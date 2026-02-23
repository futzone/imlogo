List/Search (dictations)
Fetch a paginated dictations records list, supporting sorting and filtering.

import PocketBase from 'pocketbase';

const pb = new PocketBase('https://admin.imlogo.uz');

...

// fetch a paginated records list
const resultList = await pb.collection('dictations').getList(1, 50, {
    filter: 'someField1 != someField2',
});

// you can also fetch all records at once via getFullList
const records = await pb.collection('dictations').getFullList({
    sort: '-someField',
});

// or fetch only the first record that matches the specified filter
const record = await pb.collection('dictations').getFirstListItem('someField="test"', {
    expand: 'relField1,relField2.subRelField',
});
JavaScript SDK
API details
GET
/api/collections/dictations/records

Query parameters
page	Number	The page (aka. offset) of the paginated list (default to 1).
perPage	Number	Specify the max returned records per page (default to 30).
sort	String	Specify the records order attribute(s).
Add - / + (default) in front of the attribute for DESC / ASC order. Ex.:
// DESC by created and ASC by id
?sort=-created,id
Supported record sort fields:
@random, @rowid, id, class, age, title, text, time, audio, created, updated

filter	String	Filter the returned records. Ex.:
?filter=(id='abc' && created>'2022-01-01')
expand	String	Auto expand record relations. Ex.:
?expand=relField1,relField2.subRelField
Supports up to 6-levels depth nested relations expansion.
The expanded relations will be appended to each individual record under the expand property (eg. "expand": {"relField1": {...}, ...}).
Only the relations to which the request user has permissions to view will be expanded.
fields	String	
Comma separated string of the fields to return in the JSON response (by default returns all fields). Ex.:
?fields=*,expand.relField.name

* targets all keys from the specific depth level.

In addition, the following field modifiers are also supported:

:excerpt(maxLength, withEllipsis?)
Returns a short plain text version of the field string value.
Ex.: ?fields=*,description:excerpt(200,true)
skipTotal	Boolean	If it is set the total counts query will be skipped and the response fields totalItems and totalPages will have -1 value.
This could drastically speed up the search queries when the total counters are not needed or cursor based pagination is used.
For optimization purposes, it is set by default for the getFirstListItem() and getFullList() SDKs methods.
Responses
{
  "page": 1,
  "perPage": 30,
  "totalPages": 1,
  "totalItems": 2,
  "items": [
    {
      "collectionId": "pbc_2342015160",
      "collectionName": "dictations",
      "id": "test",
      "class": "test",
      "age": "test",
      "title": "test",
      "text": "test",
      "time": 123,
      "audio": "filename.jpg",
      "created": "2022-01-01 10:00:00.123Z",
      "updated": "2022-01-01 10:00:00.123Z"
    },
    {
      "collectionId": "pbc_2342015160",
      "collectionName": "dictations",
      "id": "[object Object]2",
      "class": "test",
      "age": "test",
      "title": "test",
      "text": "test",
      "time": 123,
      "audio": "filename.jpg",
      "created": "2022-01-01 10:00:00.123Z",
      "updated": "2022-01-01 10:00:00.123Z"
    }
  ]
}

View (dictations)
Fetch a single dictations record.

import PocketBase from 'pocketbase';

const pb = new PocketBase('https://admin.imlogo.uz');

...

const record = await pb.collection('dictations').getOne('RECORD_ID', {
    expand: 'relField1,relField2.subRelField',
});
JavaScript SDK
API details
GET
/api/collections/dictations/records/:id

Path Parameters
id	String	ID of the record to view.
Query parameters
expand	String	Auto expand record relations. Ex.:
?expand=relField1,relField2.subRelField
Supports up to 6-levels depth nested relations expansion.
The expanded relations will be appended to the record under the expand property (eg. "expand": {"relField1": {...}, ...}).
Only the relations to which the request user has permissions to view will be expanded.
fields	String	
Comma separated string of the fields to return in the JSON response (by default returns all fields). Ex.:
?fields=*,expand.relField.name

* targets all keys from the specific depth level.

In addition, the following field modifiers are also supported:

:excerpt(maxLength, withEllipsis?)
Returns a short plain text version of the field string value.
Ex.: ?fields=*,description:excerpt(200,true)
Responses
{
  "collectionId": "pbc_2342015160",
  "collectionName": "dictations",
  "id": "test",
  "class": "test",
  "age": "test",
  "title": "test",
  "text": "test",
  "time": 123,
  "audio": "filename.jpg",
  "created": "2022-01-01 10:00:00.123Z",
  "updated": "2022-01-01 10:00:00.123Z"
}