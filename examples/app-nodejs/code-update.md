```javascript
require("dotenv").config();

const apikey = process.env.api_key;
const eventNotificationsHost = `${process.env.instance_location}.event-notifications.cloud.ibm.com/event-notifications/v1/instances/${process.env.instance_guid}`;
const apiSourceName = `${process.env.api_source_name}`;
const apiSourceId = `${process.env.api_source_id}`;

router.get("/custom_notification", async (req, res) => {
  let notificationId = "<not found>";
  await axios
    .post(
      "https://iam.cloud.ibm.com/identity/token",
      {
        grant_type: "urn:ibm:params:oauth:grant-type:apikey",
        apikey: `${apikey}`,
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
      console.log(tokenObject.access_token);

      axios({
        url: `https://${eventNotificationsHost}/notifications`,
        method: "post",
        data: {
          ibmenseverity: "HIGH",
          id: "0001",
          source: `${apiSourceName}`,
          ibmensourceid: `${apiSourceId}`,
          type: "*",
          ibmensubject: "Someone used the custom_notification endpoint.",
          ibmendefaultshort: "Someone used the custom_notification endpoint.",
          ibmendefaultlong: "Someone used the custom_notification endpoint.",
          specversion: "1.0",
          datacontenttype: "application/json",
        },
        // timeout: DEFAULT_TIMEOUT,
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          Authorization: `Bearer ${tokenObject.access_token}`,
        },
      })
        .then((response) => {
          console.log("Status Code:", response.status);
          console.log(response.data);
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
```