mongoose = require 'mongoose'

db = mongoose.createConnection '127.0.0.1', 'verdandi'

Qualification = module.exports.Qualification = db.model 'qualification', mongoose.Schema
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

Boundary = module.exports.Boundary = db.model 'boundary', mongoose.Schema
  _id               : mongoose.Schema.Types.ObjectId,
  title             : String,
  code              : String,
  subject           : String,
  qualification     : String,
  awarding_body     : String,
  base              : String,
  boundaries        : [
    season          : String,
    max_scaled_mark : String,
    boundaries      : {}
  ]

Exam = module.exports.Exam = db.model 'exam', mongoose.Schema
  _id           : mongoose.Schema.Types.ObjectId,
  title         : String,
  code          : String,
  subject       : String,
  qualification : String,
  awarding_body : String,
  base          : String,
  exams         : [
    start_time  : String,
    date        : String,
    duration    : String,
    session     : String
  ]
