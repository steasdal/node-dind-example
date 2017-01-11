FROM node
MAINTAINER Sam Teasdale

ADD . /
RUN npm install

EXPOSE 5000

# Start the server
CMD ["npm", "start"]
