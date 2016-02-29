Spree.ready ($) ->
  Spree.addImageHandlers = ->
    thumbnails = ($ '#product-images ul.thumbnails')
    ($ '#main-image').data 'selectedThumb', ($ '#main-image img').attr('src')
    thumbnails.find('li').eq(0).addClass 'selected'
    thumbnails.find('a').on 'click', (event) ->
      ($ '#main-image').data 'selectedThumb', ($ event.currentTarget).attr('href')
      ($ '#main-image').data 'selectedThumbId', ($ event.currentTarget).parent().attr('id')
      thumbnails.find('li').removeClass 'selected'
      ($ event.currentTarget).parent('li').addClass 'selected'
      false

    thumbnails.find('li').on 'mouseenter', (event) ->
      ($ '#main-image img').attr 'src', ($ event.currentTarget).find('a').attr('href')

    thumbnails.find('li').on 'mouseleave', (event) ->
      ($ '#main-image img').attr 'src', ($ '#main-image').data('selectedThumb')

  Spree.showVariantImages = (variantId) ->
    ($ 'li.vtmb').hide()
    ($ 'li.tmb-' + variantId).show()
    currentThumb = ($ '#' + ($ '#main-image').data('selectedThumbId'))
    if not currentThumb.hasClass('vtmb-' + variantId)
      thumb = ($ ($ '#product-images ul.thumbnails li:visible.vtmb').eq(0))
      thumb = ($ ($ '#product-images ul.thumbnails li:visible').eq(0)) unless thumb.length > 0
      newImg = thumb.find('a').attr('href')
      newModalImg = thumb.find('a').data('large')
      ($ '#product-images ul.thumbnails li').removeClass 'selected'
      thumb.addClass 'selected'
      ($ '#main-image img').attr 'src', newImg
      ($ '#product-modal-image').attr 'src', newModalImg
      ($ 'div.zoom-image-modal').children('img.zoomImg').first().attr 'src', newModalImg
      ($ '#main-image').data 'selectedThumb', newImg
      ($ '#main-image').data 'selectedThumbId', thumb.attr('id')

  Spree.updateVariantTotal = (variant) ->
    variantPrice = variant.data('total')
    ($ '.total.selling').text(variantPrice) if variantPrice
  radios = ($ '#product-variants select#variant_id option')

  Spree.updateVariantCore = (variant) ->
    variantPrice = variant.data('core')
    ($ '.core.selling').text(variantPrice) if variantPrice
  radios = ($ '#product-variants select#variant_id option')

  Spree.updateVariantPrice = (variant) ->
    variantPrice = variant.data('price')
    ($ '.price.selling').text(variantPrice) if variantPrice
  radios = ($ '#product-variants select#variant_id option')

  if radios.length > 0
    # selectedRadio = ($ '#product-variants input[type="radio"][checked="checked"]')
    selectedRadio = ($ '#product-variants select#variant_id option:selected')
    # Spree.showVariantImages selectedRadio.attr('value')
    Spree.showVariantImages selectedRadio.val()
    Spree.updateVariantPrice selectedRadio
    Spree.updateVariantTotal selectedRadio
    Spree.updateVariantCore selectedRadio

  Spree.addImageHandlers()

  radios.click (event) ->
    Spree.showVariantImages @value
    Spree.updateVariantTotal ($ this)
    Spree.updateVariantCore ($ this)
    Spree.updateVariantPrice ($ this)
