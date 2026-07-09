Title: Query a serving endpoint | Serving endpoints API | REST API reference

URL Source: https://docs.databricks.com/api/workspace/servingendpoints/query

Markdown Content:
## Query a serving endpoint

`POST/serving-endpoints/{name}/invocations`

Query a serving endpoint

API scopes (preview):[`model-serving`](https://docs.databricks.com/api/workspace/api/scopes#model-serving)

### Path parameters

[`name`](https://docs.databricks.com/api/workspace/servingendpoints/query#name)required string

The name of the serving endpoint. This field is required and is provided via the path parameter.

### Request body

[`client_request_id`](https://docs.databricks.com/api/workspace/servingendpoints/query#client_request_id)string

Optional user-provided request identifier that will be recorded in the inference table and the usage tracking table.

[`dataframe_records`](https://docs.databricks.com/api/workspace/servingendpoints/query#dataframe_records)Array of object

Pandas Dataframe input in the records orientation.

[`dataframe_split`](https://docs.databricks.com/api/workspace/servingendpoints/query#dataframe_split)object

Pandas Dataframe input in the split orientation.

[`columns`](https://docs.databricks.com/api/workspace/servingendpoints/query#dataframe_split-columns)Array of object

Columns array for the dataframe

[`data`](https://docs.databricks.com/api/workspace/servingendpoints/query#dataframe_split-data)Array of object

Data array for the dataframe

[`index`](https://docs.databricks.com/api/workspace/servingendpoints/query#dataframe_split-index)Array of int32

Index array for the dataframe

[`extra_params`](https://docs.databricks.com/api/workspace/servingendpoints/query#extra_params)object

Public preview

The extra parameters field used ONLY for completions, chat, and embeddings external & foundation model serving endpoints. This is a map of strings and should only be used with other external/foundation model query fields.

[`input`](https://docs.databricks.com/api/workspace/servingendpoints/query#input)object

Public preview

The input string (or array of strings) field used ONLY for embeddings external & foundation model serving endpoints and is the only field (along with extra_params if needed) used by embeddings queries.

[`inputs`](https://docs.databricks.com/api/workspace/servingendpoints/query#inputs)object

Tensor-based input in columnar format.

[`instances`](https://docs.databricks.com/api/workspace/servingendpoints/query#instances)Array of object

Tensor-based input in row format.

[`max_tokens`](https://docs.databricks.com/api/workspace/servingendpoints/query#max_tokens)int32

Public preview

Example`100`

The max tokens field used ONLY for completions and chat external & foundation model serving endpoints. This is an integer and should only be used with other chat/completions query fields.

[`messages`](https://docs.databricks.com/api/workspace/servingendpoints/query#messages)Array of object

Public preview

The messages field used ONLY for chat external & foundation model serving endpoints. This is an array of ChatMessage objects and should only be used with other chat query fields.

Array [

[`content`](https://docs.databricks.com/api/workspace/servingendpoints/query#messages-content)string

Public preview

Example`"What is MLflow?"`

The content of the message.

[`role`](https://docs.databricks.com/api/workspace/servingendpoints/query#messages-role)string

Public preview

Enum:

`system`

Public preview

`user`

Public preview

`assistant`

Public preview

The role of the message. One of [system, user, assistant].

 ]

[`n`](https://docs.databricks.com/api/workspace/servingendpoints/query#n)int32

Public preview

Example`5`

The n (number of candidates) field used ONLY for completions and chat external & foundation model serving endpoints. This is an integer between 1 and 5 with a default of 1 and should only be used with other chat/completions query fields.

[`prompt`](https://docs.databricks.com/api/workspace/servingendpoints/query#prompt)object

Public preview

The prompt string (or array of strings) field used ONLY for completions external & foundation model serving endpoints and should only be used with other completions query fields.

[`stop`](https://docs.databricks.com/api/workspace/servingendpoints/query#stop)Array of string

Public preview

The stop sequences field used ONLY for completions and chat external & foundation model serving endpoints. This is a list of strings and should only be used with other chat/completions query fields.

[`stream`](https://docs.databricks.com/api/workspace/servingendpoints/query#stream)boolean

Public preview

Example`true`

The stream field used ONLY for completions and chat external & foundation model serving endpoints. This is a boolean defaulting to false and should only be used with other chat/completions query fields.

[`temperature`](https://docs.databricks.com/api/workspace/servingendpoints/query#temperature)double

Public preview

Example`0.5`

The temperature field used ONLY for completions and chat external & foundation model serving endpoints. This is a float between 0.0 and 2.0 with a default of 1.0 and should only be used with other chat/completions query fields.

[`usage_context`](https://docs.databricks.com/api/workspace/servingendpoints/query#usage_context)object

Optional user-provided context that will be recorded in the usage tracking table.

### Responses

**200** Request completed successfully.

Request completed successfully.

#### Response Headers

[`served-model-name`](https://docs.databricks.com/api/workspace/servingendpoints/query#served_model_name)string

The name of the served model that served the request. This is useful when there are multiple models behind the same endpoint with traffic split.

[`choices`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices)Array of object

Public preview

The list of choices returned by the chat or completions external/foundation model serving endpoint.

Array [

[`finishReason`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices-finishReason)string

Public preview

Example`"stop"`

The finish reason returned by the endpoint.

[`index`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices-index)int32

Public preview

Example`0`

The index of the choice in the chat or completions response.

[`logprobs`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices-logprobs)int32

Public preview

Example`5`

The logprobs returned only by the completions endpoint.

[`message`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices-message)object

Public preview

The message response from the chat endpoint.

[`text`](https://docs.databricks.com/api/workspace/servingendpoints/query#choices-text)string

Public preview

Example`"MLflow is an open source platform for managing the end-to-end machine learning lifecycle."`

The text response from the completions endpoint.

 ]

[`created`](https://docs.databricks.com/api/workspace/servingendpoints/query#created)int64

Public preview

Example`1699617587`

The timestamp in seconds when the query was created in Unix time returned by a completions or chat external/foundation model serving endpoint.

[`data`](https://docs.databricks.com/api/workspace/servingendpoints/query#data)Array of object

Public preview

The list of the embeddings returned by the embeddings external/foundation model serving endpoint.

Array [

[`embedding`](https://docs.databricks.com/api/workspace/servingendpoints/query#data-embedding)Array of double

Public preview

The embedding vector

[`index`](https://docs.databricks.com/api/workspace/servingendpoints/query#data-index)int32

Public preview

Example`0`

The index of the embedding in the response.

[`object`](https://docs.databricks.com/api/workspace/servingendpoints/query#data-object)string

Public preview

Enum: `embedding`

This will always be 'embedding'.

 ]

[`id`](https://docs.databricks.com/api/workspace/servingendpoints/query#id)string

Public preview

Example`"88fd3f75a0d24b0380ddc40484d7a31b"`

The ID of the query that may be returned by a completions or chat external/foundation model serving endpoint.

[`model`](https://docs.databricks.com/api/workspace/servingendpoints/query#model)string

Public preview

Example`"gpt-4"`

The name of the external/foundation model used for querying. This is the name of the model that was specified in the endpoint config.

[`object`](https://docs.databricks.com/api/workspace/servingendpoints/query#object)string

Public preview

Enum:

`text_completion`

Public preview

`chat.completion`

Public preview

`list`

Public preview

The type of object returned by the external/foundation model serving endpoint, one of [text_completion, chat.completion, list (of embeddings)].

[`outputs`](https://docs.databricks.com/api/workspace/servingendpoints/query#outputs)Array of object

The outputs of the feature serving endpoint.

[`predictions`](https://docs.databricks.com/api/workspace/servingendpoints/query#predictions)Array of object

The predictions returned by the serving endpoint.

[`usage`](https://docs.databricks.com/api/workspace/servingendpoints/query#usage)object

Public preview

The usage object that may be returned by the external/foundation model serving endpoint. This contains information about the number of tokens used in the prompt and response.

[`completion_tokens`](https://docs.databricks.com/api/workspace/servingendpoints/query#usage-completion_tokens)int32

Public preview

Example`5`

The number of tokens in the chat/completions response.

[`prompt_tokens`](https://docs.databricks.com/api/workspace/servingendpoints/query#usage-prompt_tokens)int32

Public preview

Example`5`

The number of tokens in the prompt.

[`total_tokens`](https://docs.databricks.com/api/workspace/servingendpoints/query#usage-total_tokens)int32

Public preview

Example`10`

The total number of tokens in the prompt and response.

 This method might return the following HTTP codes: 401, 403, 404, 500

Error responses are returned in the following format:

{

"error_code":"Error code",

"message":"Human-readable error message."

}

# Possible error codes:

HTTP code

error_code

Description

401

UNAUTHORIZED

The request does not have valid authentication credentials for the operation.

403

PERMISSION_DENIED

Caller does not have permission to execute the specified operation.

404

RESOURCE_DOES_NOT_EXIST

Operation was performed on a resource that does not exist.

500

INTERNAL_ERROR

Internal error.

# Request samples

JSON

Dataframe input in split orientation

{

"dataframe_split":{

"columns":[

"sepal length(cm)",

"sepal width(cm)",

"petal length(cm)",

"petal width(cm)"

],

"data":[

[

5.1,

3.5,

1.4,

0.2

],

[

4.9,

3,

1.4,

0.2

]

],

"index":[

0,

1

]

}

}

# Response samples

200

Chat External/Foundation Model Endpoint

{

"choices":[

{

"finish_reason":null,

"index":0,

"message":{

"content":"MLflow is an open-source platf orm for managing the end-to-end machine learning(ML)lifecycle.It helps data scientists and ML eng ineers to manage and track experiments,reproduce and share results,and deploy ML models.MLflow wa s created by LinkedIn and is now a part of the Lin ux Foundation's AI and Machine Learning projects.\n\nMLflow provides a set of tools and services tha t enable data scientists and ML engineers to manag e the entire",

"role":"assistant"

}

}

],

"created":1698824353,

"id":null,

"model":"llama2-70b-chat",

"object":"chat.completion",

"usage":{

"completion_tokens":74,

"prompt_tokens":7,

"total_tokens":81

}

}
