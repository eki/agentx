# AgentX

This tool can be thought of as a web browser without the rendering part.  It
could be useful for web scraping or experimenting with an api.

There are many dependencies here, as this isn't really intended to be used as a
library in other projects.

## Usage

After you've installed the gem, you can start a repl with `agentx`.

    > agentx
    >>

Create a web session, typically with the url of the site you intend to interact
with.

    >> session = AgentX::Web::Session.new('https://api.github.com')

You can set headers at a session level (or, on individual requests).

    >> session.headers(user_agent: '')  # Set this if you want to follow this
    => {"User-Agent"=>""}               # example.

Please note that Github's api requires that you set an appropriate User-Agent.
See their documentation for more (https://developer.github.com/v3/).

Now, let's issue a request.

    >> session["/users/eki"].get
    => {"login"=>"eki", "id"=>4764, ... }

We can see that AgentX correctly identified the content-type as json, parsed
the results and returned a Ruby hash.  If the content-type had indicated that
this were html, AgentX would have parsed the result as html and returned an
AgentX::HTML (which is a thin wrapper around Nokogiri at this time).

Also, note that we specify the resource we want in square braces and then use
an HTTP verb to perform a request on that resource.  The path in square braces
is rooted against the url we used when creating the session itself.  If we
wanted to add GET or POST parameters we can do so by passing arguments to the
verb method used.

For example:

    >> session['/users'].get(since: 4763).first['id']
    => 4764

If we would like to look more closely at the requests we've issued and the
responses we've received, we can check the `history`.

    >> session.history
    => #<AgentX::Web::History:0x007fbfbba6c778 @entries=[[
       (Request GET /users/eki), (Response 200)], [(Request GET /users), 
       (Response 200)]]>

There is an array of Request, Response pairs.  We can inspect response codes,
headers, and the un-parsed body:

    >> session.history.last.response.code
    => 200
    >> session.history.last.response.headers['Link']
    => "<https://api.github.com/users?since=4794>; rel=\"next\",
        <https://api.github .com/users{?since}>; rel=\"first\""
    >> session.history.last.response.body[0..10]
    => "[{\"login\":\""

Okay, let's try something different.

    >> html = session['/r/Ruby'].get; nil
    => nil

    >> html.first('.entry a').text
    => "[Screencast] Faye Websockets - Part 2 - Setting up the Faye server in produc tion and serving WebSockets over SSL"

    >> html.first('.entry a')['href']
    => "https://www.driftingruby.com/episodes/faye-websockets-part-2"


## Installation

Add this line to your application's Gemfile:

    gem 'agentx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install agentx

## Usage

TODO: Write some documentation!

## Contributing

1. Fork it ( https://github.com/eki/agentx/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

