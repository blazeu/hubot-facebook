# Hubot Facebook Chat Adapter

## Usage
- Create a new bot, follow the instruction [here](https://hubot.github.com/docs/)
- Add hubot-facebook to your bot
```
npm install hubot-facebook --save
```
- run hubot with the Facebook adaptor
```
bin/hubot -a facebook
```

## Configuration
This adapter requires this following environment variables

- ```FB_LOGIN_EMAIL``` and ```FB_LOGIN_PASSWORD``` (this is taken from the [Schmavery/facebook-chat-api](https://github.com/Schmavery/facebook-chat-api), which this package use)
