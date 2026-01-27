# dotnet-todo

## Test the GET endpoints

Test the app by calling the endpoints from a browser or Postman. The following steps are for Postman.

  Create a new HTTP request.
  Set the HTTP method to GET.
  Set the request URI to https://localhost:<port>/todoitems. For example, https://localhost:5001/todoitems.
  Select Send.

The call to GET /todoitems produces a response similar to the following:

```json
[
  {
    "id": 1,
    "name": "walk dog",
    "isComplete": false
  }
]
```

  Set the request URI to https://localhost:<port>/todoitems/1. For example, https://localhost:5001/todoitems/1.

  Select Send.

  The response is similar to the following:

```json
  {
    "id": 1,
    "name": "walk dog",
    "isComplete": false
  }
```

This app uses an in-memory database. If the app is restarted, the GET request doesn't return any data. If no data is returned, POST data to the app and try the GET request again.
