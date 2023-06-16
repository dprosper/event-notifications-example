// require expressjs
const express = require("express");
const app = express();
const axios = require("axios");

// define port 8080
PORT = 8080;
app.use(express.json());
// use router to bundle all routes to /
const router = express.Router();
app.use("/", router);
// get on root route

router.get("/", async (req, res) => {
  res.send("hello world!");
});

require("dotenv").config();

const appGeneratedEventId = "0001";

router.get("/custom_notification", async (req, res) => {
  let notificationId = "<not found>";
  await axios
    .post(
      "https://iam.cloud.ibm.com/identity/token",
      {
        grant_type: "urn:ibm:params:oauth:grant-type:apikey",
        apikey: `${process.env.api_key}`,
      },
      {
        headers: {
          Accept: "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )
    .then((response) => {
      let tokenObject = response.data;

      axios({
        url: `https://${process.env.instance_location}.event-notifications.cloud.ibm.com/event-notifications/v1/instances/${process.env.instance_guid}/notifications`,
        method: "post",
        data: {
          ibmenseverity: "HIGH",
          id: `${appGeneratedEventId}`,
          source: `${process.env.api_source_name}`,
          ibmensourceid: `${process.env.api_source_id}`,
          type: "*",
          ibmensubject: "Someone used the custom_notification endpoint.",
          ibmendefaultshort: "Someone used the custom_notification endpoint.",
          ibmendefaultlong: "Someone used the custom_notification endpoint.",
          specversion: "1.0",
          datacontenttype: "application/json",
        },
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${tokenObject.access_token}`,
        },
      })
        .then((response) => {
          notificationId = response.data.notification_id;
        })
        .catch((err) => {
          console.log(err);
        });
        
    })
    .catch((err) => {
      console.log("Error: ", err.message);
    });

  res.send(`An event notification was sent using notification id: ${notificationId}.`);
});

// start server
app.listen(PORT, () => {
  console.log("Server is up and running!!");
});
