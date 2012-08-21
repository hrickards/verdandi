ignore /css/
ignore /config\.rb/

before 'index.html' do
  system "compass compile"
  system "sprocketize -c public .stylesheets-cache/screen.css"
end
