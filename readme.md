## freshservice-api ##
A Ruby API client that interfaces with freshservice.com web service. This client supports regular CRUD operation 

Freshservice's API docs are here [http://freshservice.com/api/](http://freshservice.com/api/)

As of now, it supports the following: 

  - tickets
  - problems
  - changes
  - releases
  - users
  - solution_categories
  - departments
  - assets(config_items)

## Usage Example ##

```
client = Freshservice.new("http://companyname.freshservice.com/", "user@domain.com", "password")  
# note trailing slash in domain is required

response = client.get_users  
client.get_users 123  
client.post_users(:name => "test", :email => "test@143124test.com")  
client.put_users(:id =>123, :name => "test", :email => "test@143124test.com")  
client.delete_tickets 123  

```

## GET request ##

```
client.get_tickets(id - optional)
client.get_problems(id - optional)
client.get_changes(id - optional)
client.get_releases(id - optional)
client.get_users(id - optional)
client.get_solution_categories(id - optional)
client.get_departments(id - optional)
client.get_config_items(id - optional)
```

## POST request ##

```
client.post_users(key1 => value, key2 => value2, ...)

# example posts a ticket
client.post_tickets(:email => "user@domain.com", :description => "test ticket from rails app", :source => 2, :priority => 2, :name => "Joshua Siler")
# etc.
```

## DELETE request ##

```
client.delete_users(id - required)
# etc.
```

## Authors ##
- @dvliman
- @tsmacdonald




