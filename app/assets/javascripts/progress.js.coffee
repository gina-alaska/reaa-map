class @Progress
  constructor: (@target, @msg, @percent) ->
    @start()
    
  next: =>
    @start()

    @percent += 10
    @percent = 0 if @percent > 100
    # @update(@percent)
    
  update: (percent) =>
    @start()
    percent = 100 if percent > 100
    @progress.find('.progress-bar').css('width', "#{percent}%")
  
  start: =>
    return false if @progress?
    
    @percent = 100
    
    @progress = $('<div class="progress-popup">
      <div class="progress progress-striped active">
        <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 100%;">
          <span class="">' + @msg + '</span>
        </div>
      </div>
    </div>')    
    $(@target).append(@progress)
  
  done: =>
    @update(100)
    @progress.fadeOut()   
    delete @progress 