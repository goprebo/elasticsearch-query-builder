# Ruby Elasticsearch::QueryBuilder

Ruby gem for building complex ElasticSearch queries using clauses as methods. Supports query and function_score builders, as well as clients to fetch results.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elasticsearch-query-builder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elasticsearch-query-builder

## Usage

Instantiate the class

```ruby
elastic_query = ElasticSearch::QueryBuilder.new(opts: {}, client: nil, function_score: false)
```

### Initialize parameters

| Parameter      | Type    | Default | Description                                                                                                                                              |
|----------------|---------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| opts           | Hash    | {}      | Optional. Initial query. Each method will add a clause to the @opts object.                                                                              |
| client         | Object  | nil     | Optional. Client to fetch results from ElasticSearch. elasticsearch-model clients is an useful gem for this.                                             |
| function_score | Boolean | false   | Optional. Whether to include clauses inside a function_score path and therefore be able to use .functions() methods to calculate custom document scores. |

### Behaviour

#### Methods definition

Available methods and paths are:

- must: [ query bool must ],
- must_not: [ query bool must_not ],
- should: [ query bool should ],
- functions: [ functions ],
- ids: [ query terms _id ],
- size: [ size ],
- fields: [ _source ],
- range: [ bool must range ],
- sort: [ sort ],
- aggs: [ aggs ]

Once the class is loaded, each method is defined and path **query function_score** is appended if class was initialized with **function_score: true** and original path starts with **query**.

#### init_path

Each path is initialized if not added previously to the query. If already added, it's appended to existing path preserving all previous clauses.

#### exclude_opposite

**must** and **must_not** are exclusive paths. The QueryBuilder do its best to recognize if an opposite clauses was previously added and remove it preserving only the last exclusive clause.

#### add_clause

Once the path is built and the opposite is excluded, the clause is merged with all the other clauses.

### Methods

#### .must([clauses])

Receives an array of clauses and insert them in **query: { bool: { must: [] } }** path. If clause was previously added with .must_not() it is replaced.

**Example**
```ruby
elastic_query.must([ { range: { sign_in_count: { gte: 3 } } } ])

# elastic_query.send(:opts)
{
    query: {
        bool: {
            must: [
                range: {
                    sign_in_count: { gte: 3 }
                }
            ]
        }
    }
}
```

#### .must_not([clauses])

Receives an array of clauses and insert them in **query: { bool: { must_not: [] } }** path. If clause was previously added with .must() it is replaced.

**Example**
```ruby
elastic_query.must_not([ { range: { sign_in_count: { gte: 3 } } } ])

# elastic_query.send(:opts)
{
    query: {
        bool: {
            must_not: [
                range: {
                    sign_in_count: { gte: 3 }
                }
            ]
        }
    }
}
```

#### .should([clauses])

Receives an array of clauses and insert them in **query: { bool: { should: [] } }** path.

**Example**
```ruby
elastic_query.should([ { range: { sign_in_count: { gte: 3 } } } ])

# elastic_query.send(:opts)
{
    query: {
        bool: {
            should: [
                range: {
                    sign_in_count: { gte: 3 }
                }
            ]
        }
    }
}
```

#### .functions([functions])

Receives an array of functions to calculate document score. .functions() is overridden if .sort() method is called. Functions are inserted in **query: { function_score: { functions: [] } }** path.

**Example**
```ruby
elastic_query.functions([ { script_score: { script: "1 - ( 1.0 / ( doc['popularity'].value == 0 ? 1 : doc['popularity'].value ))" }, weight: 1 } ])

# elastic_query.send(:opts)
{
    query: {
        function_score: {
            functions: [
                { script_score: { script: "1 - ( 1.0 / ( doc['popularity'].value == 0 ? 1 : doc['popularity'].value ))" }, weight: 1 }
            ]
        }
    }
}
```

#### .ids([array of ids])

Receives an array of ids to retrieve. Ids are inserted in **query: { terms: { _id: [] } }** path.

**Example**
```ruby
elastic_query.ids([1, 4, 6])

# elastic_query.send(:opts)
{
    query: {
        terms: {
            _id: [
                1,
                4
                6
            ]
        }
    }
}
```

#### .size(Integer)

Receives an integer representing the number of documents to retrieve. Size is a root attribute in **size: size** path. Each time .size() method is called, size attribute is overridden.

.size(0) returns all metadata but documents.

**Example**
```ruby
elastic_query.size(200)

# elastic_query.send(:opts)
{
    query: {
    },
    size: 200
}
```

#### .fields([fields])

Receives an array of fields to retrieve for each document. Each field is appended to **_source** path.

**Example**
```ruby
elastic_query.fields([:name, :category, :created_at])

# elastic_query.send(:opts)
{
    query: {
    },
    _source: [:name, :category, :created_at]
}
```

#### .range([body])

Subtype of .must() method. Receives an array of clauses representing ranges of fields. Each clause is appended to **query bool must range** path.

**Example**
```ruby
elastic_query.range([{ sign_in_count: { gte: 3 } }])

# elastic_query.send(:opts)
{
    query: {
        bool: {
            must: [
                range: [
                    {
                        sign_in_count: { gte: 3 }
                    }
                ]
            ]
        }
    }
}
```

#### .sort(field)

Receives a field to sort query results by. Each time .sort() method is called, sort attribute is overridden. It also disables .functions() score.

**Example**
```ruby
elastic_query.sort([popularity: { order: :desc }])

# elastic_query.send(:opts)
{
    query: {
    },
    sort: [
        { popularity: { order: :desc } }
    ]
}
```

#### .aggs([aggs fields])

Receives an array of fields to aggregate results count by. If body is not needed, .size(0) will still return aggregated count.

**Example**
```ruby
elastic_query.sort([aggs: { ages: { terms: { field: 'median_age' } } }])

# elastic_query.send(:opts)
{
    query: {
    },
    aggs: [
        { ages: { terms: { field: 'median_age' } } }
    ]
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on Gituhub at https://github.com/goprebo/elasticsearch-query-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Elasticsearch::QueryBuilder project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/goprebo/elasticsearch-query-builder/blob/master/CODE_OF_CONDUCT.md).

## Contact

You may contact Prebo at support@goprebo.com or in https://www.goprebo.com/