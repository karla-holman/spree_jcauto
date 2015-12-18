$( document ).ready(function(){
	$("#coupon_apply").show();
});

// Handle shipping prices on final price
$("#checkout_form_delivery").change( function() {

	var tax_price = 0;
	var promo_price = 0;

	// Get total cost of shipping
	var $selected = $("#checkout_form_delivery input[type='radio']:checked");

	var ship_price = 0; 

	$selected.each(function( index ) {
	  var prices = $( this ).siblings(".rate-cost").text().match(/\$\d*.\d*/g);

	  for( var i = 0; i < prices.length; i++ ) {
	  	ship_price += parseFloat(prices[i].replace('$', ''));
	  }
	});

	// Get tax cost
	if ( $("tbody[data-hook='order_details_tax_adjustments']").find("td").length ) {
		var $tax_total = $("tbody[data-hook='order_details_tax_adjustments']").find("td")[1];
		tax_price = parseFloat($tax_total.textContent.replace('$', ''));
	}

	// Get promotion
	if ( $("tbody#summary-order-charges .total").length ) {
		var $promo_total = $("tbody#summary-order-charges .total").find("td")[1];
		promo_price = parseFloat($promo_total.textContent.replace('-$', ''));
	}

	// Get total item price
	var $item_total = $("tr[data-hook='item_total']").children()[1];
	var item_price = parseFloat($item_total.textContent.replace('$', ''));

	// Add the two for total
	var $order_total = $("#summary-order-total");
	var total_price = item_price + tax_price + ship_price - promo_price;
	$order_total.text("$" + (total_price).toFixed(2).toString());
});

$("#coupon_apply").click(function(event) {
	event.preventDefault();

	var coupon_code, coupon_code_field, coupon_status, url;
	coupon_code_field = $('#order_coupon_code');
	coupon_code = $.trim(coupon_code_field.val());
	if (coupon_code !== '') {
		if ($('#coupon_status').length === 0) {
		  coupon_status = $("<div id='coupon_status'></div>");
		  coupon_code_field.parent().append(coupon_status);
		} else {
		  coupon_status = $("#coupon_status");
		}
		url = Spree.url(Spree.routes.apply_coupon_code(Spree.current_order_id), {
		  order_token: Spree.current_order_token,
		  coupon_code: coupon_code
		});
		coupon_status.removeClass();
		return $.ajax({
		  async: false,
		  method: "PUT",
		  url: url,
		  success: function(data) {
		    coupon_code_field.val('');
		    coupon_status.addClass("alert-success").html("Coupon code applied successfully.");
		    // return true;
		    location.reload();
		  },
		  error: function(xhr) {
		    var handler;
		    handler = JSON.parse(xhr.responseText);
		    coupon_status.addClass("alert-error").html(handler["error"]);
		    $('.continue').attr('disabled', false);
		    return false;
		  }
		});
	}
});