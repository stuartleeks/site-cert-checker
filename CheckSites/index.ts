import { AzureFunction, Context } from "@azure/functions"
import * as https from "https";
import { PeerCertificate, TLSSocket } from "tls";

function getCertificateForSite(host: string): Promise<PeerCertificate> {
    return new Promise<PeerCertificate>((resolve, reject) => {
        try {
            const req = https.request({
                host,
                port: 443,
                path: '/',
                method: 'GET',
                rejectUnauthorized: false
            }, (res) => {
            const certificate = (res.socket as TLSSocket).getPeerCertificate();
                resolve(certificate);
            });
            req.end();
        } catch (error) {
            reject(error);
        }
    });
}
function subtractDays(date: Date, daysToSubtract: number) {
    const newDate = new Date(date);
    newDate.setDate(date.getDate() - daysToSubtract);
    return newDate;
}

const timerTrigger: AzureFunction = async function (context: Context, myTimer: any): Promise<void> {
    context.log('SitesToCheck starting 😀');

    const sitesEnvVar = process.env['SitesToCheck'] ?? '';
    if (!sitesEnvVar) {
        throw new Error('SitesToCheck application setting not set');
    }
    const sitesToCheck = sitesEnvVar.split('|');
    const expiryEnvVar = process.env['ExpiryGraceDays'] ?? '7';
    const expiryGraceDays = parseInt(expiryEnvVar, 10);

    const work = sitesToCheck.map(async site => {
        try {
            const cert = await getCertificateForSite(site);
            const validFrom = new Date(cert.valid_from);
            const validTo = new Date(cert.valid_to);
            const now = new Date(Date.now());
            const expiryCheckDate = subtractDays(now, expiryGraceDays);

            context.log({
                site, validFrom, validTo, expiryCheckDate, issuer: cert.issuer?.O
            })
            let message = null;
            if (validFrom > now) {
                message = `!!![${site}] Cert not yet valid: ${validFrom}`;
            } else if (validTo < expiryCheckDate) {
                message = `!!![${site}] Cert expired: ${validTo}`;
            }

            if (message){
                context.log(message);
            }

        } catch (error) {
            context.log(error);
        }
    });

    await Promise.all(work);
};

export default timerTrigger;
