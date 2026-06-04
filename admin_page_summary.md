##### ADMIN DASHBOARD



Overview	Total users, active today, mood entries, AI requests today, recent activity feed, API key status

Users		Search/filter/sort table, create/edit/delete modals, join date, last active, session count

User Detail	Mood history timeline, songs played/skipped, AI interactions per user

Song Analytics	Most played/skipped bar charts, mood→song mapping table, skip/play rates

AI Logs		Prompt→Response pairs, user→mood→AI output

Activity Logs	Admin action log + error log (reads errors.txt)

Settings	Feature toggle switches + branding editor (app name, colors, tagline)





##### ENDPOINTS



/admin/stats		POST		Summary stats: total users, active today, new this week, total mood entries, AI requests today



/admin/users		POST		All users with search/filter/sort params



/admin/users/create	POST		Create new user



/admin/users/update	POST		Edit user name/email/password



/admin/users/delete	POST		Delete user + cascade



/admin/user/detail	POST		Mood history, song log, AI interactions for one user



/admin/song-analytics	POST		Most played songs, mood → song mapping, skip/replay rates



/admin/activity-log	POST		Who did what (login/song plays/ai requests)



/admin/error-log	POST		Recent app errors logged to a file



/admin/ai-responses	POST		Prompt → Response pairs, user mood → AI output log



/admin/feature-toggles	POST (GET/SET)	Read/write feature flags from a JSON config file



/admin/branding		POST		Read/write branding config (theme color, app name)







##### DATABASE ADDED



AdminLog — activity log (user\_email, action, timestamp, detail)

AiRequestLog — prompt, response snippet, user\_email, timestamp (logged when /get-song or /get-ai-insights is called)







##### FEATYRE TOGGLE



admin\_config.json	Feature toggles and branding config file (read/written by Flask).











