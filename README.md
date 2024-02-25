# AI मित्र
<center>

![logo](android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png)
</center>

Chat with Google Gemini using Text, Image, Voice. <br>
[![made-with-flutter](https://img.shields.io/badge/Made%20with-Flutter-1f425f.svg)](https://flutter.dev/) ![Release](https://img.shields.io/github/v/release/sapatevaibhav/ai_mitra)  <br>

### What is supported
<center>
- ✅ Chat with Text. <br>
- ✅ Chat with Gallery Image.<br>
- ✅ Chat with Camera Image.<br>
- ✅ Chat with voice.<br>
- ❌ Chat with pdf file. (Working on it)
</center>

### Getting Started

Requirenments
 - Flutter 
 - Gemini's API Key


To get started with the **this** app, follow these simple steps:

> #### Clone the Git Repository
>
> ```bash
> git clone https://github.com/sapatevaibhav/ai_mitra
> ```

> ### Run the Flutter Project
>
>Ensure you have Flutter installed. If not, you can follow the instructions on [Flutter.dev](https://flutter.dev/) to get it installed on your machine.
>
>Navigate to the project directory using the terminal.
>
>Run the following command to fetch the >dependencies:
>```bash 
>flutter pub get
>```
>Once the dependencies are fetched, run the app on your preferred device using:
>```bash
>flutter run
>```
>That's it! The app should now be running on your device/emulator.


> [!Note] 
> During development I tested this app on.
> * OnePlus gaucamoleb.
> * Operating System - Project Elixir v4.1 A14.


> [!dependencies]
>- Flutter: 3.16.0
>- Dart: 3.2.0
>- sdk: '>=3.2.0 <4.0.0'
>- cupertino_icons: ^1.0.2
>- google_generative_ai: ^0.2.0
>- flutter_markdown: ^0.6.19
>- url_launcher: ^6.2.4
>- adaptive_theme: ^3.6.0
>- speech_to_text: ^6.6.0
>- image_picker: ^1.0.7
>- camera: ^0.10.5+9
>- path_provider: ^2.1.2
>- path: ^1.8.3
>- hive: ^2.2.3
>- DevTools: 2.28.2

### Image division

As of currently there is limitation of Image size sent to Gemini to overcome this in this app I have implemented a logic which divides the entire image in the smaller chuncks of 1 MB each and then it is sent to Gemini here is breakdown of process.

![Image](Screenshots/draw.svg)

### ScreenShots
- home (light)<br>
<img src="Screenshots/01.png" width=200>
- home (dark)<br>
<img src="Screenshots/02.png" width=200>
- Select image<br>
<img src="Screenshots/03.png" width=200>
- Settings<br>
<img src="Screenshots/04.png" width=200>
- Change API key<br>
<img src="Screenshots/05.png" width=200>
- Clear History<br>
<img src="Screenshots/06.png" width=200>
- Useful snackbar<br>
<img src="Screenshots/07.png" width=200><img src="Screenshots/08.png" width=200>