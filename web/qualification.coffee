mongoose = require 'mongoose'

db            = mongoose.createConnection '127.0.0.1', 'verdandi'
schema        = mongoose.Schema
           _id                 : mongoose.Schema.Types.ObjectId,
           subject             : String,
           qualification       : String,
           awarding_body       : String,
           base                : String,
           units               : [
             title             : String,
             code              : String,
             exams             : [
               start_time      : String,
               date            : String,
               duration        : String,
               session         : String
             ],
             boundaries        : [
               season          : String,
               max_scaled_mark : String,
               boundaries      : {}
             ]
           ]
Qualification = module.exports = db.model 'qualification', schema
