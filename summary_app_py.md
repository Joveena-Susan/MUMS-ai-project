* Flask, request, jsonify → to create API routes and send JSON responses
* load\_dotenv → to load API keys from .env
* CORS → to allow frontend apps to call the backend
* os → file paths and environment variables
* requests → external API calls such as YouTube
* datetime → session timestamps
* google.genai and errors → Gemini API integration



##### Authentication routes



register() - Registers a new user



login() - Authenticates an existing user





##### History sync routes



sync\_history() - Saves the full session history sent from the frontend into the backend database



get\_history\_api() - Returns saved history for a user





##### Preference sync routes



sync\_preferences() - Stores user song preferences



get\_preferences\_api() - Returns blocked and liked songs.





##### Helper function



\_song\_key(title, artist) - Creates a normalized song identity key





##### YouTube search route



youtube\_search\_api() - Searches YouTube for a playable/embeddable video for a given song query





##### Mood detection route



detect\_mood\_api() - Detects user mood from text





##### Song recommendation route



get\_song\_api() - This is one of the core functions of the app. It detects mood, decides a target mood, builds Spotify queries, filters songs, and returns recommended songs.





##### Song logging routes



log\_song() - Logs whether a song was played or skipped



get\_played\_songs() - Returns all logged songs for a given user and mood



clear\_played\_songs() - Deletes all song play logs for a user





##### Session outcome logging



**log\_session\_outcome()** - Stores rich session behavior for later AI analysis

Expected fields may include:

* email
* session\_date
* start\_mood
* end\_mood
* start\_intensity
* end\_intensity
* songs\_played\_count
* songs\_skipped\_count
* liked\_songs\_count
* mood\_improved
* session\_duration\_secs





##### AI insights route



get\_ai\_insights() - Generates personalized emotional insights for the user using session history and Gemini. This is the analytics + personalization intelligence part of the app.



* Creates summary features for insight generation
* Identifies when the user most often relies on music (morning, etc.)
* Finds emotionally difficult days
* Shows which moods respond well or poorly to music
* Understands listening behavior in different emotional states (skips per mood, plays per mood)
* Adds preference awareness to insights (counts liked and blocked)
* Transforms raw analytics into human-friendly emotional feedback (using gemini)





##### Rule-based insight fallback



\_rule\_based\_insights(...) - Generates simple insights when Gemini is unavailable or errors out







### **End-to-end flow of this backend**



A simple real flow would be:



User opens app

* logs in using /login



User enters or speaks text

* frontend sends text to /get-song



Backend does this

* detects mood
* computes intensity
* decides target mood
* creates Spotify queries
* fetches tracks
* filters blocked/played songs
* returns songs



Frontend picks a song

* may call /youtube-search to get embeddable video ID



During session

* app logs played/skipped songs via /log-song



After session ends

* app sends session performance to /log-session-outcome



Later

* app calls /get-ai-insights
* backend generates personalized insight text



Preferences/history sync

* handled through sync routes



