# WWW-3095 Event Request Form Modal

On the national and local theme pages, we want to display a div with a link to an 'Event Request Form' modal window.  It should not appear for mobile users.  This is just an extension of the experiment found here: 

- [JIRA](https://kapowevents.atlassian.net/browse/WWW-3824)
- [Optimizely STG Experiment](https://app.optimizely.com/projects/4930876202/experiments/5677050568)
- [Optimizely Dev Experiment](https://app.optimizely.com/projects/4955530742/experiments/5680650635)


## URL Targeting
Leave the this target alone:
`.+/events/[a-zA-Z-]+/$` (regex match)
And add this target:
`.+/events/theme/([^\/]+/)?type/[a-zA-Z]+/$` (regex match)

## variation 1 js
We just need to change this line:
`$rowHolder = $('.deck:not(.no-results) .row.holder')`
To this:
`$rowHolder = $('.deck:not(.no-results) .cards-container')`
