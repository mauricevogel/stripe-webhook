
# Stripe Webhook

This repository contains a solution for the Datarade coding challenge.

## Why this solution?

The solution I'm presenting is fulfilling the mentioned acceptance criteria of the challenge, providing tests for all components, and trying to follow good practices. I will quickly run you through the core pillars of it and the decisions I took.

### The `StripeWebhooksController`
The controller follows rails conventions, using the `create` route for it being a POST endpoint. Its primary responsibility is to validate the incoming events using the Stripe gem and then store a local representation of the event, which will also trigger the enqueuement of a background job to do the actual processing.

This solution was chosen as webhooks should generally respond fast, thus the actual processing parts had to be moved out of the regular request/response cycle. For this application, it probably wouldn't make a huge difference though.

### The `StripeEvent` model
As mentioned above this one is used for local representation of events we're interested in and to enqueue a job to process them after creation. This decision was primarily made to prevent the processing of duplicated events, enable easy audits if ever required, and make it easy to pass (and serialize/deserialize) it as an argument to the processing job.

If the above-mentioned use cases wouldn't matter, one could've also enqueued the job from the controller directly using the Stripe event object in combination with the `Marshal` library (for dumping/loading it).

### The  `Subscription` model

This one holds a simple local representation of a stripe subscription with minimal data currently. It comes with a state machine that handles transitions and thus prevents unwanted ones like canceling an unpaid subscription.

### The `ProcessStripeEventsJob`

Holds the actual logic to process the events. I kept it fairly simple and added inline comments describing further decisions I took over there.

### Easy start-up

The app is not containerized, yet I added a development `Procfile` and bash script to easily start all important parts for running and testing the application locally.

## How to run the application

### Requirements
```  
Ruby 3.3.0 
PostgreSQL
Stripe CLI installed and logged into  
```  

### Setup the database
```  
$ rails db:setup  
```  
### Add the Stripe webhook secret to your dev credentials
```yaml  
stripe:  
 webhook_secret: "your_stripe_webhook_secret"  
```  

The webhook secret can be obtained using the output of the stripe event forwarding command:
```  
$ stripe listen --forward-to localhost:3000/stripe_webhooks  
```  

### Start the server

This will automatically start the rails server, a worker to process jobs, and the stripe event forwarding using the stripe CLI.

```  
$ bin/dev  
```

### Run linting and tests
```
$ bundle exec rubocop # linter
$ rails test # tests
```


