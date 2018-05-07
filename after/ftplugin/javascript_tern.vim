if !has('python3')
  echo 'tern requires python 3 support'
  finish
endif

call tern#Enable()
