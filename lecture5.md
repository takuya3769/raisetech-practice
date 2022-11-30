# Raisetech 第五回講義

## 課題内容

- ローカル環境でのアプリケーションデプロイ
- nginx + unicorn でのアプリケーションデプロイ
- ALB 設置及びアプリ動作確認
- S3 作成
- 課題のインフラ構成図作成

## 前提条件

- 第四回課題、EC2 構築及び RDS 接続ができる環境がある
- 前回まではターミナル上での操作で実施したが今回は Vs Code 上で SSH 接続を行いそちらで課題を進める。

## Vs Code 上での SSH 接続手順

1.  VS code 内で拡張機能である「remote ssh」をインストールする。検索バーで打てば一番上に出てくる。
2.  左下に緑のボタンが表示されていればインストールされているのでクリック
3.  Connect to host を選んで config ファイルがある場所を選択する(ない場合は作成)
4.  ファイルの中に ssh で接続するための情報を記入
    Host { 任意の名称 例: test }
    HostName { 作成した EC2 のパブリック IPv4 アドレス 例: 11.11.11.11 }
    IdentityFile { キーペアのパス 例: /Users/{ユーザー名}/.ssh/test.pem }
    User ec2-user(amazon-Linux2 の場合,他の os の場合は調べること)
5.  ここまで入力できれば保存して、再度左下のボタンを押して接続できるかどうか確認する。接続が失敗する場合は秘密鍵の場所を確認。
6.  これでエディタを使うことが可能。

- 注意点:今のままだと EC2 を停止した時にパブリック IP が毎回変更になり config ファイルをその都度修正しなければいけないので固定 IP である Elastic IP を使用すれば修正がなくなるので検討しても良い。料金の高くはないので面倒であれば使用する。

## EC2 に Ruby インストール

EC2 起動、接続は SSH 接続 OS は Amazon Linux2

1. ssh ec2-user@ec2-xx-xx-xx-xxx.ap-northeast-1.compute.amazonaws.com -i ~/.ssh/my_key.pem
   SSH 接続完了
   アップデートがある場合は以下のコマンドを入力
2. sudo yum update
   Git インストール
3. sudo yum install git
   rbenv をクローン
4. git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
5. git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
   PATH を通す
6. echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
7. echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
8. source ~/.bash_profile
   Rbenv のバージョン確認
9. rbenv -v
   インストールできていれば rbenv ~~~と表示される
   インストールできる ruby のバージョン確認
10. rbenv install —list
    インストールできる ruby のバージョンが表示される
    2.7.6
    3.0.4
    3.1.2
    jruby-9.3.9.0
    mruby-3.1.0
    picoruby-3.0.0
    rbx-5.0
    truffleruby-22.3.0
    truffleruby+graalvm-22.3.0
    Ruby をビルドするために必要なライブラリをインストール
11. sudo yum install -y gcc openssl-devel zlib-devel
    Ruby をビルド ➡︎ 時間はかかるかもしれない
12. rbenv install 3.1.2
    Rbenv で使用する Ruby のバージョンを指定
13. rbenv global 使用したい Ruby version
    バージョン確認
14. ruby -v 先ほど指定した version が表示されれば OK

ここまでのコマンドのみ記す

1. ssh ec2-user@ec2-xx-xx-xx-xxx.ap-northeast-1.compute.amazonaws.com -i ~/.ssh/my_key.pem
2. sudo yum update
3. sudo yum install git
4. git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
5. git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
6. echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
7. echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
8. source ~/.bash_profile
9. rbenv -v
10. rbenv install —list
11. sudo yum install -y gcc openssl-devel zlib-devel
12. rbenv install 使用したい Ruby version
13. rbenv global 使用したい Ruby version
14. ruby -v

## EC2 に Rails 環境を構築する

1. sudo yum install -y git gcc openssl-devel readline-devel zlib-devel sqlite-devel
2. git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
3. git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
4. echo ‘export PATH=”$HOME/.rbenv/bin:$PATH”‘ >> ~/.bash_profile
5. echo ‘eval “$(rbenv init -)”‘ >> ~/.bash_profile
6. source ./.bash_profile
7. rbenv install –list
8. rbenv install 2.5.0
9. rbenv global 2.5.0
10. rbenv rehash
11. gem install bundler sqlite3 rails
12. rails –version
13. rails new testApp
14. cd testApp
15. sudo yum install curl
16. sudo yum install epel-release
17. curl –silent –location https://rpm.nodesource.com/setup_8.x | sudo bash –
18. sudo yum install nodejs
19. rails s

- 追加事項 rails s ローカル環境での接続できない時は EC2 画面上 IPv4、パブリック IP やインバウンド設定を見直す。

## EC2 上にサンプルアプリをクローンする

1.  git clone クローンしたいアプリケーション
2.  sudo yum install mysql
3.  gem 'sassc', '~> 2.1.0’
4.  sudo touch /tmp/mysql.socket
5.  mysql_config --socket
6.  app/config/database.yml
7.  username admin
8.  password mysql 作成時の password
9.  host RDS エンドポイント
10. socket /var/lib/mysql/mysql.sock
11. rails db:create
12. rails db:migrate
13. npm install
14. npm run build
15. rails s

## Nginx Unicorn で Rails アプリを起動させる

### nginx のインストールから Amazon linux2 では amazon-linux-extras を使ってインストールする。

1. which amazon-linux-extras
2. amazon-linux-extras インストールできるファイル一覧表示
3. sudo amazon-linux-extras install nginx1
4. nginx -v バージョン確認
5. sudo cp -a /etc/nginx/nginx.conf /etc/nginx/nginx.conf.back
6. sudo systemctl start nginx 起動コマンド
7. systemctl status nginx 設定確認
8. パブリック IP をコピペしてブラウザで確認
9. sudo systemctl stop nginx

### unicorn のインストール

1. gem ‘unicorn’
2. 今回はインストールされているので unicorn.rb の設定を変更するだけ
   listen,pid を編集,今回は nginx+unicorn でのデプロイがメインのため sock ファイル,pid ファイルの場所をいじることはしないがセキュリティの面を考えると場所の移動は必要(var/www への移動)

### Nginx + unicorn でのデプロイ

1. sudo systemctl start nginx
2. systemctl status nginx
3. bundle exec unicorn_rails -c config/unicorn.rb -D 開発環境で動かす
4. パブリック ip でアクセス
5. ps aux | grep unicorn
6. Kill -9 ~~~~~
   (5~6 は unicorn 停止コマンド)
7. sudo systemctl stop nginx (nginx 停止)
8. systemctl status nginx
   ローカル環境と nginx+unicorn の環境でレイアウト等の違いがあるので明日はそこを修正。
   sudo vi /etc/nginx/conf.d/raisetech-live8-sample-app.conf

location ^~ /assets/ {
gzip_static on;
expires max;
add_header Cache-Control public;
}
vi で開いた nginx の設定画面から上記を削除すればレイアウトの崩れはなくなる。

## ELB(ALB)

参考サイト https://zoo200.net/aws-tutorial-alb-ec2-2/

- アプリケーションロードバランサー設定方法
  EC2 ダッシュボードからロードバランサーをクリック
  ロードバランサー作成ボタンがあるので新規作成
  今回は ALB（アプリケーションロードバランサーを選択）
  各種設定をポチポチクリックしながら行う。

- 基本設定
  名前 任意の名前
  スキーム インターネット向け
  Ip アドレス ipv4

- リスナー
  ロードバランサーのプロトコル HTTP
  ポート 80

- AZ
  VPC 自身で作成した EC2 を選択
  AZ 二ヶ所選択する必要があり public サブネットを選択すること、private サブネットは選択しない。

- アドオンサービス タグ
  任意で行う

- セキュリティグループ作成
  新規のセキュリティグループを作成する。
  タイプ HTTP
  プロトコル TCP
  範囲 80
  ソース カスタム 0.0.0.0

- ルーティング設定
  ターゲットグループ 新しいターゲットグループ
  名前 任意の名前
  ターゲットの種類 インスタンス
  プロトコル HTTP
  ポート 80
  プロトコルバージョン HTTP1

- ヘルスチェック
  プロトコル HTTP
  パス /
  詳細設定に関してはそのまま

- ターゲットグループ選択
  作成している EC2 インスタンスを選ぶ
  ここまで出来たら最終確認画面に移るので変更がなければ作成すれば ALB の立ち上げ完了。

ロードバランサーの DNS をコピペしてブラウザでアクセスできるか確認する。
初回アクセス時に Block host で URL にアクセス出来ないと思うのでエラーメッセージの通りに development.rb の設定を行う。
Nginx,unicorn を再起動してアクセス出来るか確認。

## Rails アプリケーションの画像を S3 に保存する

参考サイト https://qiita.com/ysda/items/49fa6e8318c874a57b9e
https://zenn.dev/banrih/articles/f22f0a70bbead2a02110

1. ダッシュボードから S3 作成
   一般的な設定
   ［バケット名］任意の名前
   ［AWS リージョン］VPC と同じ
   オブジェクト所有者
   ［ACL 無効 (推奨)］を選択
   このバケットのブロックパブリックアクセス設定
   ［パブリックアクセスをすべて ブロック］チェックを外す
   ［現在の設定により、このバケットとバケット内のオブジェクトが公開される可能性があることを承認します。］チェックする
   バケットのバージョニング
   ［バージョニング］無効にする（本番では有効にした方がいい）
   デフォルトの暗号化
   ［サーバー側の暗号化］無効にする
   詳細設定
   ［オブジェクトロック］無効にする
2. S3 権限を持つ IAM ユーザー作成
   IAM ダッシュボードから［ユーザー］-［ユーザーを追加］をクリック
   ［ユーザー名］任意の名前
   ［AWS 認証情報タイプを選択］アクセスキー - プログラムによるアクセス
   ［アクセス許可の設定］既存のポリシーを直接アタッチ
   ［AmazonS3FullAccess］を選択
   作成したら［.csv ファイルをダウンロード］する ← のちの設定で必要になるのでダウンロード必須
3. credentials.yml.enc と master.key を新規に作成
   rm config/credentials.yml.enc
   EDITOR="vi" bin/rails credentials:edit
   credentials:edit ファイルが開くので以下を記述する、yml ファイルなのでインデント注意
   aws:
   access_key_id: ＜ S3 バケットの Access key ID ＞
   secret_access_key: ＜ S3 バケットの Secret access key ＞
   active_storage_bucket_name: ＜ S3 のバケット名＞
4. credentials を開発環境へ移す
   EDITOR=vim bundle exec rails credentials:edit --environment development
5. config/environments/development.rb を編集
   config.active_storage.service = amazon
6. バケットポリシー設定
   ダッシュボードからバケットを選択しポリーシーをクリック

   ```HTML
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "〇〇〇〇〇＜S3用に作成したIAMユーザーのARN＞"
            },
            "Action": "S3:*",
            "Resource": [
                "arn:aws:s3:::〇〇〇〇〇＜S3のバケット名＞",
                "arn:aws:s3:::〇〇〇〇〇＜S3のバケット名＞/*"
            ]
        }
    ]
   }
   ```

7. アクセス許可設定

   ```HTML
   [
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "POST",
            "PUT",
            "DELETE",
            "HEAD"
        ],
        "AllowedOrigins": [
            "〇〇〇〇〇＜ELBのDNS名＞"
        ],
        "ExposeHeaders": [
            "Access-Control-Allow-Origin"
        ]
    }
   ]
   ```

## インフラ構成図

![picture 1](images/f15103d80fcaaa720ec3a60184ccbb43a14568969ef4e540186ba058201fe054.png)


## 今回の学習を終えての感想

今回の課題は前回の課題に比べて非常にハマるポイントが多く、完成するまでに時間がかかった。環境構築はそれほど苦戦はせずに出来たがローカル環境でのアプリケーションのデプロイが最初にハマったポイント。アプリケーションをクローンしてから[bundle install]を実行した時にエラーが出て rails アプリケーションが立ち上がらなかったこと、なんとかエラーを解決した後に接続を試みるもなぜかアクセス出来ない問題。課題の途中で rails7.0 系に切り替えがあったのでそちらへのアップデートを行うとレイアウトが崩れてしまう問題となかなかに苦しみました。
一通り解決が終わって nginx+unicorn でのアプリのデプロイのも苦戦、こちらはローカル環境で効いていた CSS が反応しなかったのを解決するのが大変でした。
ALB に関してはサイトを参考にしながらポチポチ実施していくだけなので比較的スムーズには出来たと思います。
最大のハマりポイントが S3 エラーの意味がなかなかわからずメンターさんと講師さんに助けれてなんとか解決できたが二日間立ち止まってしまった時は心が折れそうでした。ただ今回の課題を通してエラー内容の裏付けや質問することで現状の課題を解決していく一つの訓練になったように思うので苦しみはしたけれど得られるものはめちゃくちゃ多い課題でした。
インフラ構成図は苦労しながらなんとかかけたので確認して貰おう。
