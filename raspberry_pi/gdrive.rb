#! /usr/bin/ruby
# -*- coding: utf-8; mode: ruby -*-
# Function:
#   Lazurite Sub-GHz/Lazurite Pi Gateway Sample program
#   SerialMonitor.rb

require "google_drive"
require "net/http"

# GoogleDriveを扱うためのモジュール。
# 認証情報の取得補助や、Gdrive::Sessionインスタンスの生成を行う。
# @version 1.0.0
module Gdrive

  # 認証用コード取得用のURLフォーマット
  # @private
  CODE_URL_FORMAT = "https://accounts.google.com/o/oauth2/auth?client_id=%s&redirect_uri=%s&scope=https://www.googleapis.com/auth/drive&response_type=code&approval_prompt=force&access_type=offline"
  # リフレッシュトークンを取得するURL
  # @private
  REFRESH_TOKEN_URL = "https://accounts.google.com/o/oauth2/token"

  # Gdrive::Sessionインスタンスを生成する
  #
  #「Google Developers Console」よりクライアントID、クライアントシークレットを予め生成しておく必要がある。
  # また、リフレッシュトークンを予め取得しておく必要がある。
  #
  # @param [String] client_id     クライアントID
  # @param [String] client_secret クライアントシークレット
  # @param [String] refresh_token リフレッシュトークン
  # @return [Gdrive::Session] Gdrive::Sessionインスタンス
  #
  # @raise [Gdrive::NetworkError] ネットワーク関連エラー
  # @raise [Gdrive::OAuthError]   OAuth認証関連エラー
  # @raise [Gdrive::GoogleError]  GoogleAPI関連エラー
  # @raise [Gdrive::Error]        その他のエラー
  #
  # @see Gdrive.create_session
  # @see Gdrive.create_oauth2_url
  # @since 1.0.0
  def self.create_session(client_id, client_secret, refresh_token)
    begin
      client = OAuth2::Client.new(
        client_id,
        client_secret,
        site: "https://accounts.google.com",
        token_url: "/o/oauth2/token",
      authorize_url: "/o/oauth2/auth")
      auth_token = OAuth2::AccessToken.from_hash(
      client, {:refresh_token => refresh_token, :expires_at => 3600})
      auth_token = auth_token.refresh!
      session = GoogleDrive.login_with_oauth(auth_token.token)
      Session.new(session)
    rescue => e
      raise Error.select_error e
    end
  end

  # OAuth2認証用のコードを取得するために、ユーザへブラウザでアクセスしてもらうURLを生成する。
  #
  # GoogleDriveを使用するためには、本APIで生成するURLを用いて、ユーザがGoogleDriveへアクセスすることを許可し、
  # 認証用情報を取得してもらう必要がある。
  # 「Google Developers Console」よりクライアントID、リダイレクトURLを予め生成しておく必要がある。
  # @note 本APIは認証の初期手順を補助するためのものであり、リフレッシュトークン取得後は使用する必要はない。
  #
  # @param [String] client_id    クライアントID
  # @param [String] redirect_uri リダイレクトURI
  # @return [String] OAuth2認証用コード取得URL
  #
  # @since 1.0.0
  def self.create_oauth2_url(client_id, redirect_uri)
    CODE_URL_FORMAT % [client_id, redirect_uri]
  end

  # リフレッシュトークンなどが含まれたJSONデータを取得する。
  #
  # JSONデータ内にリフレッシュトークン情報が含まれているため、それを用いてGdrive::Sessionクラスを生成する。
  # 引数に誤りがあるなどして認証に失敗した場合、JSONデータ内にはエラー情報が含まれる。
  # 「Google Developers Console」よりクライアントID、クライアントシークレット、リダイレクトURLを予め生成しておく必要がある。
  # また、予めユーザにGoogleDriveへのアクセスを認証してもらい、認証用コードを取得してもらう必要がある。
  # @note 本APIは認証の初期手順を補助するためのものであり、リフレッシュトークン取得後は使用する必要はない。
  #
  # @param [String] client_id     クライアントID
  # @param [String] client_secret クライアントシークレット
  # @param [String] redirect_uri  リダイレクトURI
  # @param [String] code          OAuth2認証用コード
  # @return [String] JSONデータ
  #
  # @raise [Gdrive::NetworkError] ネットワーク関連エラー
  # @raise [Gdrive::GoogleError]  GoogleAPI関連エラー
  # @raise [Gdrive::Error]        その他のエラー
  #
  # @since 1.0.0
  def self.get_oauth2_token(client_id, client_secret, redirect_uri, code)
    params = {
      client_id:     client_id,
      client_secret: client_secret,
      redirect_uri:  redirect_uri,
      grant_type:    "authorization_code",
      code:          code,
    }
    begin
      url = URI.parse(REFRESH_TOKEN_URL)
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(params)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      res = http.start { |client| client.request(req) }
      res.body
    rescue => e
      raise Error.select_error e
    end
  end

  # 認証情報を格納し、GoogleDriveへアクセスするためのクラス。
  # 本クラスよりスプレッドシートを作成する。
  class Session

    # @private
    def initialize(google_drive_session)
      @session = google_drive_session
    end

    # 指定された名称のスプレッドシートを操作するインスタンスを取得する。
    # 存在しない名称が指定された場合は、スプレッドシートが新規作成される。
    #
    # 名称にはフォルダ名を含むことが出来ず、どのフォルダにスプレッドシートを配置していても良い。
    # ただし、同じ名称のスプレッドシートが複数存在する場合には、最初に見つけたものを使用する。
    # また、スプレッドシートを新規生成する場合はルートに作成する。
    #
    # @param [String] name スプレッドシート名
    # @return [Gdrive::SpreadSheet] Gdrive::SpreadSheetインスタンス
    #
    # @raise [Gdrive::NetworkError] ネットワーク関連エラー
    # @raise [Gdrive::GoogleError]  GoogleAPI関連エラー
    # @raise [Gdrive::Error]        その他のエラー
    #
    # @since 1.0.0
    def open_spreadsheet(name)
      begin
        sheet = @session.spreadsheet_by_title(name)
        unless sheet
          sheet = @session.create_spreadsheet(title=name)
        end
        SpreadSheet.new(sheet)
      rescue => e
        raise Error.select_error e
      end
    end

  end

  # スプレッドシートへ操作を行うクラス。
  class SpreadSheet

    # @private
    def initialize(google_spreadsheet)
      @spreadsheet = google_spreadsheet
    end

    # スプレッドシートシートへ一行書き込む。
    # スプレッドシートの一番下にあるデータの行の次の行へ書き込まれる。
    #
    # @param [Integer] worksheet    書き込むワークシートのindex
    # @param [Array<String>] values 1行に書き込む文字列をカラムごとに区切ったArray
    # @return [bool] 存在しないワークシートが指定された場合はfalseを返す
    #
    # @raise [Gdrive::NetworkError] ネットワーク関連エラー
    # @raise [Gdrive::GoogleError]  GoogleAPI関連エラー
    # @raise [Gdrive::Error]        その他のエラー
    #
    # @since 1.0.0
    def write_line(worksheet, values)
      begin
        wss = @spreadsheet.worksheets
        if wss.length > worksheet
          ws = wss[worksheet]
          # 一番下の次の行へ書き込む
          row = ws.num_rows + 1
          values.each.with_index do |value, index|
            ws[row, index+1] = value
          end
          ws.save
          true
        else
          false
        end
      rescue => e
        raise Error.select_error e
      end
    end

  end

  # 各エラーの規定クラス
  # 種類が不明なエラーを表す
  class Error < StandardError

    # @private
    def self.select_error(error)
      case
      when error.is_a?(Faraday::Error)     then NetworkError.new(error)
      when error.is_a?(OAuth2::Error)      then OAuthError.new(error)
      when error.is_a?(GoogleDrive::Error) then GoogleError.new(error)
      else Error.new(error)
      end
    end

    # @private
    def initialize(error)
      super(error.message)
    end

  end
  # ネットワークエラー
  class NetworkError < Error
  end

  # OAuth認証エラー
  class OAuthError < Error
  end

  # GoogleのAPI関連のエラー
  class GoogleError < Error
  end

end
