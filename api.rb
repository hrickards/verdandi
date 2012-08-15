class Seshat::API < Grape::API
  version 'v1', :using => :path
  format :json

  resource :exams do
    desc "Get a list of all exams"
    get '/' do
      Exam.all
    end
  end
end
