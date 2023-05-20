require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'bundler/setup'

require_relative 'models/question'
require_relative 'models/user'
require_relative 'models/answer'

set :database, { adapter: "sqlite3", database: "db.sqlite3" }

class App < Sinatra::Application
  
  enable :sessions
  register Sinatra::Cookies

  def initialize(app = nil)
    super()
  end

  get '/' do
    erb :index
  end

  get '/register' do
    erb :register
  end

  post '/registermenu' do
    @name = params[:name]
    @password = params[:password]
    @firstname = params[:firstname]
    @lastname = params[:lastname]
    @email = params[:email]
    @reppw = params[:reppw]

    user_exists = User.find_by(name: @name)

    if @reppw != @password
      @msgfail = "Las contraseñas no coinciden"
      erb :fail_register
    elsif @password.length < 6
      @msgfail = "Su contraseña es muy corta. El mínimo es de 6 caracteres"
      erb :fail_register
    elsif user_exists != nil
      @msgfail = "Ya existe un usuario con ese nombre de usuario. Por favor, elige otro"
      erb :fail_register
    else
      user = User.create(name: @name, password: @password,
                         firstname: @firstname, lastname: @lastname,
                         email: @email, points: 0)
      session[:user_id] = user.id
      erb :argentina
    end
  end

  post '/logmenu' do
    @user = User.find_by(name: params[:name], password: params[:password])

    if @user
      session[:user_id] = @user.id

      erb :argentina
    else
      @msg = "Usuario y/o contraseña incorrectos. Inténtalo nuevamente"

      erb :fail_login
    end
  end

  get '/menu' do
    redirect '/' unless current_user

    erb :argentina
  end

  get '/ranking' do
    @usersname = User.select(:name).order(points: :desc)
    @userspoints = User.select(:points).order(points: :desc)
    @n = 0

    erb :ranking
  end

  get '/question/:id' do
    @question = Question.find_by(id: params[:id])
    @answers = Answer.where(question_id: @question.id)
    @user = current_user

    erb :question

    rescue Exception
      @msg = '¡Felicidades! Te pasaste ChefTravel, por ahora...'
      erb :nomorequest
  end

  post '/question' do
    option_id = params[:option_id].to_i
    option = Answer.find(option_id)

    if option.correct

      result_message = "¡CORRECTO!"
      if @question.difficulty.to_i == 1
        current_user.update(points: current_user.points.to_i + 10)
      elsif @question.difficulty.to_i == 2
        current_user.update(points: current_user.points.to_i + 20)
      else
        current_user.update(points: current_user.points.to_i + 30)
      end

    else

      result_message = "INCORRECTO"
      if @question.difficulty.to_i == 1
        current_user.update(points: current_user.points.to_i - 10)
      elsif @question.difficulty.to_i == 2
        current_user.update(points: current_user.points.to_i - 20)
      else
        current_user.update(points: current_user.points.to_i - 30)
      end

    end

    erb :result, locals: { result_message: result_message, id: @question.id }
  end

  def current_user
    User.find_by(id: session[:user_id])
  end
  
end
