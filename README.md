# **An implementation of the [Connect Four](http://en.wikipedia.org/wiki/Connect_Four) game on Ruby on Rails**

Below are the features of the game:

1. **User Account Management**

2. **Real-time Player vs Player**

3. **Score Tracking**

This is also developed using the following tools:

1. [Faye PubSub](http://faye.jcoglan.com/)

   Used primarily to manage pub-sub events messaging.

2. [Gon](https://github.com/gazay/gon)

   Used to pass controller variables to the coffeescript files.

3. [Devise](https://github.com/plataformatec/devise)

   User management and authentication.

4. [Delayed Job](https://github.com/collectiveidea/delayed_job_active_record)

   Used to queue message events published to the Faye server.
