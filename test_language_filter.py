from spotify_client import is_track_in_language


def test_malayalam_detection():
    # native script should be accepted
    assert is_track_in_language("കാറ്റ്", "സുരേഷ്", "malayalam")
    # known artist should pass
    assert is_track_in_language("Ayalathe Sundari", "sushin shyam", "malayalam")
    # english/global hits should be rejected
    assert not is_track_in_language("Gangnam Style", "PSY", "malayalam")
    assert not is_track_in_language("Shape of You", "Ed Sheeran", "malayalam")


def test_hindi_detection():
    assert is_track_in_language("दिलबर", "नीहा कक्कड़", "hindi")
    assert not is_track_in_language("Let It Be", "The Beatles", "hindi")


def test_telugu_detection():
    assert is_track_in_language("జై హో", "హ arr हो\"?" , "telugu")
    # fallback to artist list
    assert is_track_in_language("Some Song", "devi sri prasad", "telugu")
    assert not is_track_in_language("Gangnam Style", "PSY", "telugu")


def test_tamil_detection():
    assert is_track_in_language("காதல்", "அனிருத்", "tamil")
    assert not is_track_in_language("Shake It Off", "Taylor Swift", "tamil")


def test_english_detection():
    # plain English track should pass
    assert is_track_in_language("Poker Face", "Lady Gaga", "english")
    # non-English scripts should block
    assert not is_track_in_language("दिलबर", "नीहा कक्कड़", "english")
    assert not is_track_in_language("കാറ്റ്", "സുരേഷ്", "english")
    # artist from other language list should block
    assert not is_track_in_language("Some Song", "sushin shyam", "english")
    assert not is_track_in_language("Some Song", "yo yo honey singh", "english")
    assert not is_track_in_language("Some Song", "vishal mishra", "english")
    # new Hindi artists should also be rejected
    assert not is_track_in_language("Kiya Kiya", "Anand Raj Anand", "english")
    assert not is_track_in_language("Kamariya", "Aastha Gill", "english")
    assert not is_track_in_language("Sundari", "Sanju Rathod", "english")
    assert not is_track_in_language("Bom Diggy Diggy", "Zack Knight", "english")
    assert not is_track_in_language("Chikni Chameli", "Ajay-Atul", "english")
    assert not is_track_in_language("Proper Patola", "Badshah", "english")
    # keyword-based filtering
    assert not is_track_in_language("Dhurandhar", "Shashwat Sachdev", "english")
    assert not is_track_in_language("Na Ja", "Pav Dharia", "english")
