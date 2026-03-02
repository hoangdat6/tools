const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

const client = new SESClient({ region: "us-east-1" });

async function send() {
    const result = await client.send(
        new SendEmailCommand({
            Source: "dev@bdm-ap.dev.kaopiz.com",
            Destination: {
                ToAddresses: ["dathv2+1612@kaopiz.com"]
            },
            Message: {
                Subject: { Data: "Test SES from EC2 Ubuntu" },
                Body: {
                    Text: { Data: "Hello 👋\nMail này được gửi từ EC2 Ubuntu thông qua AWS SES." }
                }
            }
        })
    );
    console.log("MessageId:", result.MessageId);
}

send().catch(console.error);
