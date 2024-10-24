
# Google Places Suggestions Autocomplete Field

### Example on macos
![](https://github.com/TopCode-Dev/google_places_suggestions_autocomplete_field/blob/master/example.gif)

`google_places_suggestions_autocomplete_field` is a Flutter package that provides a form text field for location search and autocompletion using the Google Places API. This widget not only returns text into the provided controller but also provides detailed location information via a callback function. The location details returned include:

- Full address
- City
- Postal/Zip Code
- Country
- Latitude and Longitude coordinates
- Province
- Suburb

The library is highly customizable, allowing you to specify the countries where the location search should be restricted to, along with customizable UI properties such as hint text, background color, and text style.

### Features

- Location suggestions based on user input.
- Fetches detailed place information from Google Places API.
- Returns full address details, including city, postal code, country, latitude, longitude, province, and suburb.
- Supports customizable country restrictions for the search results.
- Customizable UI components such as text styles, hint text, and background color for the suggestions list.

### Installation

Add the following dependency to your pubspec.yaml file:
```yaml
dependencies:
    google_places_suggestions_autocomplete_field: [latest version]
```

Then run:
```bash

flutter pub get
```


### Usage
#### Basic Usage Example

Here is how you can integrate the `GooglePlacesSuggestionsAutoCompleteField` widget into your Flutter app:


```dart

class LocationPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Places Autocomplete'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GooglePlacesSuggestionsAutoCompleteField(
          controller: TextEditingController(), // Controller to manage the text input
          googleAPIKey: "YOUR_GOOGLE_API_KEY_HERE", // Your Google Places API key
          countries: "za", // Restricting the search to a country like South Africa (use ISO 3166-1 alpha-2 codes)
          onPlaceSelected: (place) {
            debugPrint("Selected place: ${jsonEncode(place.toJson())}");
          },
        ),
      ),
    );
  }
}
```

#### Parameters Explained

1. `controller` (required): The TextEditingController controls the input in the text field and can be used to retrieve the selected address as a string.
2. `googleAPIKey` (required): Your Google Places API key for authenticating and fetching the location suggestions. Ensure that this API key has the appropriate billing setup and permissions for using Google Places API.
    
3. `onPlaceSelected` (required): A callback function triggered when a place is selected from the list of suggestions. This returns a Place object with detailed location data (address, city, postal code, country, latitude/longitude, province, and suburb).
    
4. `countries` (optional): A comma-separated list of country codes (ISO 3166-1 alpha-2) to restrict the location search results to specific countries. By default, it is set to "za" (South Africa).
    
5. `hint` (optional): The hint text to be displayed in the text field (default: "Address").
    
6. `decoration` (optional): Custom InputDecoration for the text field. If not provided, a default decoration with a location icon and a border will be used.
    
7. `suggestionBackgroundColor` (optional): The background color for the suggestion list. The default color is white (Colors.white).
    
8. `suggestionDividerColor` (optional): The color of the divider between suggestions. The default color is a dark shade of black (Colors.black87).
    
9. `suggestionTextStyle` (optional): Custom text style for the suggestions shown in the dropdown list. If not provided, it uses a default font style.

#### Example with Optional Fields

Below is an example that demonstrates how to use the optional fields to customize the widget's appearance:

```dart
class LocationPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Places Autocomplete'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GooglePlacesSuggestionsAutoCompleteField(
          controller: TextEditingController(), // Manages the input text field
          googleAPIKey: "YOUR_GOOGLE_API_KEY_HERE", // Your Google API Key
          hint: "Search for a location", // Custom hint text for the input field
          decoration: InputDecoration(
            labelText: "Enter Address",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ), // Custom decoration for the text field
          suggestionBackgroundColor: Colors.lightBlue.shade50, // Background color for the suggestions list
          suggestionDividerColor: Colors.blueAccent, // Divider color between the suggestions
          suggestionTextStyle: TextStyle(
            fontSize: 16,
            color: Colors.blueAccent,
          ), // Custom text style for suggestions
          countries: "us,ca,mx", // Restrict the location search to the USA, Canada, and Mexico
          locationType: "geocode", // Use geocode to return geographical coordinates
          onPlaceSelected: (place) {
            debugPrint("Selected place: ${jsonEncode(place.toJson())}");
          }, // Callback function that handles the selected place data
        ),
      ),
    );
  }
}
```

### Place Object Details

The Place object returned by the onPlaceSelected callback contains the following information:

- `address`: The full formatted address of the selected place.

- `city`: The city where the place is located.

- `postalCode`: The postal or zip code of the place.
    
- `country`: The country where the place is located.
    
- `latitude`: The latitude coordinate of the place.
    
- `longitude`: The longitude coordinate of the place.
    
- `province`: The province or state where the place is located.
    
- `suburb`: The suburb or locality of the place.

## Google API Key Setup

To use this package, you will need to set up a Google API key:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/apis/library/places.googleapis.com)
    
2. Create a new project or select an existing one.
    
3. Enable the "Places API" and "Geocoding API" for the project.
    
4. Create API credentials (API key).
    
5. Make sure the API key has the necessary permissions and is restricted to authorized platforms (Android, iOS, Web).

### Example Output

When a user selects a place from the suggestions, the onPlaceSelected callback will return a Place object with the detailed information like:
