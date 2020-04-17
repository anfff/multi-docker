# base image
FROM node:alpine

# working directory
WORKDIR '/app'

# copy package.json
COPY ./package.json ./

# install npm
RUN npm install

# copy other stuff from folder
COPY . .

# set defualt command - here we will gona run nodemon used to automatically reload entire project if source code in project
# has changed
CMD ["npm", "run", "start"]