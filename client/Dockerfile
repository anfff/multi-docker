# FIRST PHASE - BUILD PHASE
    # BASE IMAGE - name build stage as builder
    FROM node:alpine as builder

    # SET UP WORKING DIRECTORY IN CONTAINER
    WORKDIR '/app'

    # COPY json package
    COPY ./package.json ./

    # INSTALL DEPENDENCIES
    RUN npm install

    # COPY EVERYTHING ELSE
    COPY . .

    # SETUP BUILD PROCES - THIS CREATE A BUILD FOLDER - path to that folder will be /app/build (this is what we care about)
    # in this folders the production assets will be stored
    RUN npm run build

# SECOND PHASE - RUN PHASE
    # BASE IMAGE
    FROM nginx

    # EXPOSE PORT
    EXPOSE 3000

    # COPY nginx default.conf  (/client/nginx/default.conf) to overwrite the existing defualt configuration file
    COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

    # COPY RESULT OF BUILD PHASE called builder from folder /app/build/ to specified folder from nginx documentation
    COPY --from=builder /app/build /usr/share/nginx/html

    # DEFAULT COMMAND OF NGINX IS GOING TO START UP NGINX FOR US, WE DON'T NEED TO SPECIFY ANTYHING