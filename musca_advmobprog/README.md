# musca_advmobprog

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Lab Activity 2: Discussion

The Model, Service, and Screen have different roles, but they work together to display data from the API. The Model organizes the data received from the API, while the Service is responsible for getting that data from the API. The Screen then uses the data and displays it to the user. From this activity, I understood that separating these parts makes the code easier to understand because I know which part is responsible for a specific task.

This activity also helped me understand the separation of concerns design pattern. Instead of putting everything in one file, the Model handles the data, the Service handles the API requests, and the Screen focuses on the user interface. We also use Provider to manage the app's theme and state. By working with this structure, I learned how the different parts of the application connect and why organizing the code this way makes it easier to maintain and update.
