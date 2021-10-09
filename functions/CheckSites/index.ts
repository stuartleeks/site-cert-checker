import { AzureFunction, Context } from "@azure/functions"
import { IncomingMessage } from 'http'
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
function addDays(date: Date, daysToAdd: number) {
    const newDate = new Date(date);
    newDate.setDate(date.getDate() + daysToAdd);
    return newDate;
}

interface ExpiryDetails {
    site: string;
    validFrom: Date;
    validTo: Date;
    message: string;
}
function sendExpiryNotification(expiryPostUrl: string, details: ExpiryDetails) {
    const data = new TextEncoder().encode(JSON.stringify(details));
    return new Promise<IncomingMessage>((resolve, reject) => {
        const req = https.request(expiryPostUrl, response => {
            resolve(response);
        });
        req.method = 'POST';
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Content-Length', data.length);
        req.write(data);
        req.end();
    })
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

    const expiryPostUrl = process.env['ExpiryPostUrl'] ?? '';
    if (!sitesEnvVar) {
        throw new Error('ExpiryPostUrl application setting not set');
    }


    const work = sitesToCheck.map(async site => {
        try {
            const cert = await getCertificateForSite(site);
            const validFrom = new Date(cert.valid_from);
            const validTo = new Date(cert.valid_to);
            const now = new Date(Date.now());
            const expiryCheckDate = addDays(now, expiryGraceDays);

            let message = null;
            if (validFrom > now) {
                message = `!!![${site}] Cert not yet valid: ${validFrom}`;
            } else if (validTo < now) {
                message = `!!![${site}] Cert expired: ${validTo}`;
            } else if (validTo < expiryCheckDate) {
                message = `!!![${site}] Cert expiry near: ${validTo}`;
            }

            context.log({
                site, validFrom, validTo, expiryCheckDate, issuer: cert.issuer?.O, message
            });
            if (message) {
                context.log('Calling expiryPostUrl...');
                var response = await sendExpiryNotification(expiryPostUrl, { site, validFrom, validTo, message });
                context.log(`Calling expiryPostUrl...done: ${response.statusCode} ${response.statusMessage}`);
            }

        } catch (error) {
            context.log(error);
        }
    });

    await Promise.all(work);
};


export default timerTrigger;