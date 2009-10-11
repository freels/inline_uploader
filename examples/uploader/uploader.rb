require 'rubygems'
require 'sinatra'
require 'inline_uploader'
require 'fileutils'

save_dir = File.join(Dir.pwd, 'public/uploads')
FileUtils.mkdir_p save_dir

# teh app

set :port, 3000
enable :show_exceptions

use InlineUploader

helpers do
  include InlineUploader::Helpers
end

get '/' do
  entries = Dir[File.join(save_dir, '*')]
  haml :index, :locals => {:entries => entries}
end

post '/save_upload' do
  upload = params[:upload]
  path   = File.join(save_dir, File.basename(upload[:filename]))
  FileUtils.move(upload[:tempfile].path, path)

  redirect '/'
end

template :index do
  <<-end_haml
!!! Strict
%html
  %head
    %script(type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js")
    %script(type="text/javascript" src="/ajaxfileupload.js")
    :javascript
      $(function(){
        $('#submit_upload').click(function(){
          $.ajaxFileUpload({
            url : '/inline_upload',
            fileElementId : 'upload_field',
            success : function(){
              $('#upload_container').text('File uploaded.');
            }
          });

          $('#upload_container').text('Uploading...');

          return false;
        });
      });

  %body
    %h1 uploads
    %ul
      - entries.each do |entry|
        %li= entry

    %h2 Add something new:

    %form(method="POST" action="/save_upload")
      %input(type="hidden" name="has_inline_uploads" value="1")
      %input(type="hidden" name="upload" value="\#{inline_upload_tag}")

      %div#upload_container
        %input(type="file" id="upload_field" name="\#{inline_upload_tag}")
        %a#submit_upload(href="#") upload file

      %div
        %input(type="submit" value="Save")
  end_haml
end

