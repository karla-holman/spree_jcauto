---
title: Product applications
description: Use the Spree Commerce storefront API to access Productapplication data.
---

<%= warning "Requests to this API will only succeed if the user making them has access to the underlying products. If the user is not an admin and the product is not available yet, users will receive a 404 response from this API." %>

## Index

List

Retrieve a list of all product applications for a product by making this request:

    GET /api/products/1/product_applications

Product applications are paginated and can be iterated through by passing along a `page` parameter:

    GET /api/products/1/product_applications?page=2

### Parameters

page
: The page number of product application to display.

per_page
: The number of product applications to return per page

### Response

<%= headers 200 %>
<%= json(:product_application) do |h|
{ :product_applications => [h],
  :count => 10,
  :pages => 2,
  :current_page => 1 }
end %>

## Search

To search for a particular product application, make a request like this:

    GET /api/products/1/product_applications?q[application_name_cont]=bag

The searching API is provided through the Ransack gem which Spree depends on. The `application_name_cont` here is called a predicate, and you can learn more about them by reading about [Predicates on the Ransack wiki](https://github.com/ernie/ransack/wiki/Basic-Searching).

The search results are paginated.

### Response

<%= headers 200 %>
<%= json(:product_application) do |h|
 { :product_applications => [h],
   :count => 10,
   :pages => 2,
   :current_page => 1 }
end %>

### Sorting results

Results can be returned in a specific order by specifying which field to sort by when making a request.

    GET /api/products/1/product_applications?q[s]=application_name%20desc

## Show

To get information about a single product application, make a request like this:

    GET /api/products/1/product_applications/1

Or you can use a application's name:

    GET /api/products/1/product_applications/size

### Response

<%= headers 200 %>
<%= json(:product_application) %>

## Create

<%= admin_only %>

To create a new product application, make a request like this:

    POST /api/products/1/product_applications?product_application[application_name]=size&product_application[value]=10

If a application with that name does not already exist, then it will automatically be created.

### Response

<%= headers 201 %>
<%= json(:product_application) %>

## Update

To update an existing product application, make a request like this:

    PUT /api/products/1/product_applications/size?product_application[value]=10

You may also use a application's id if you know it:

    PUT /api/products/1/product_applications/1?product_application[value]=10

### Response

<%= headers 200 %>
<%= json(:product_application) %>

## Delete

To delete a product application, make a request like this:

    DELETE /api/products/1/product_applications/size

<%= headers 204 %>

