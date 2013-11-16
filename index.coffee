
(->

  # fix select2 in modal
  $.fn.modal.Constructor.prototype.enforceFocus = ->

  Handlebars.registerHelper('line-style', (type) ->
    return {
      '背景图': 'danger'
      '可鉴赏的背景图': 'danger'
      '背景音乐': 'primary'
      '音效': 'warning'
      '时间标记': 'success'
    }[type] || 'default'
  )


  template = Handlebars.compile($('#lines').html())
  lines = []
  values = []

  loadData = ->
    lines = JSON.parse(localStorage.getItem('lines')) || []

    $('#lines').html(template(lines))

    $('#line-count').text(lines.length)

    values = _.groupBy(lines, 'type')
    for own k, v of values
      pluck_key = if k == '对白' then 'character' else 'value'
      values[k] = _.unique(_.pluck(v, pluck_key).reverse())

  saveData = ->
    lines = $('#lines > div').map ->
      $type = $(this).find('.type')
      type = $type.data('type') || $type.text()
      value = $(this).find('input').val()
      line = type: type, value: value
      line.character = $type.text() if type == '对白'
      return line
    lines = lines.get()
    localStorage.setItem('lines', JSON.stringify(lines))

  $('#selector').on('hidden.bs.modal', ->
    $('#selector-select').select2('destroy').val('')
    $('#selector-gallery').addClass('hide').bootstrapSwitch('setState', false)
  )

  popupSelector = ->
    type = $(this).data('type') || $(this).text()
    value = $(this).parent().next('input').val()
    value = $(this).text() if type == '对白' && value?

    $('#selector-type').text(if type == '对白' then '角色' else type)
    $('#selector-select').val(value).select2
      tags: values[type] || []
      maximumSelectionSize: 1
      tokenSeparators: []
    $('#selector-gallery').removeClass('hide') if type == '背景图'
    $('#selector').prop('target', $(this).parents('.input-group')).modal()

  deltaLineCount = (n = 1) ->
    $lineCount = $('#line-count')
    $lineCount.text(parseInt($lineCount.text()) + n)

  $('#selector-submit').click ->
    $target = $('#selector').prop('target')
    type = $('#selector-type').text()
    type = '对白' if type == '角色'
    value = $('#selector-select').val()
    values[type] = _.union([value], values[type])
    source =
      if type == '对白'
        type: type
        value: if ($target.length > 0) then $target.find('input').val() else ''
        character: value
      else
        type: type
        value: value
    if type == '背景图'
      source.gallery = $('#selector-gallery').bootstrapSwitch('status')
    $rendered = $(template([source]))
    bindLinesEvent($rendered)
    if ($target.length > 0)
      $target.replaceWith($rendered)
    else
      $('#lines').append($rendered)
    $('#selector').modal('hide')
    deltaLineCount(1)

  bindLinesEvent = ($field = $('#lines')) ->
    $field.find('.type').click(popupSelector)
    $field.find('.moveUp').click ->
      $container = $(this).parents('.input-group')
      $container.prev().before($container)
    $field.find('.moveDown').click ->
      $container = $(this).parents('.input-group')
      $container.next().after($container)
    $field.find('.delete').click ->
      $(this).parents('.input-group').remove()
      deltaLineCount(-1)

  $('#save').click ->
    saveData()
    alert('保存成功')

  $('#download').click ->
    saveData()
    blob = new Blob([JSON.stringify(lines, null, '\t')], type: 'application/octet-stream')
    $('#downloader').attr(
      href: URL.createObjectURL(blob)
      download: moment().format('YYYY-MM-DD_HH.mm.ss[.json]')
    )[0].click()

  $('#openfile').click ->
    $('#uploader')[0].click()

  $('#uploader').change ->
    file = this.files[0]
    reader = new FileReader()
    reader.onload = (e) ->
      lines = JSON.parse(e.target.result)
      localStorage.setItem('lines', JSON.stringify(lines))
      window.location.reload()
    reader.readAsText(file)

  $('.add-line a').click(popupSelector)

  $('#clear').click ->
    if confirm('确定要清空所有内容吗？')
      localStorage.removeItem('lines')
      window.location.reload()

  loadData()
  bindLinesEvent()

)()