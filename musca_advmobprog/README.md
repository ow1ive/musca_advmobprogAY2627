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

## Lab Activity 3: Discussion

In this activity, I learned how the Cart Model, Cart Service, and Cart Screen work together when getting data from an API. The Cart Model is used to organize the information from the API, such as the cart ID, user ID, products, quantity, and total. The Cart Service is responsible for calling the API and converting the JSON response into data that the app can understand. Then, the Cart Screen displays that information to the user. I also learned that the products in the cart can still use the existing `detail_screen.dart`, so there is no need to create another detail screen.

This activity also helped me understand the design pattern better because each part of the app has its own responsibility. The model handles the data, the service handles the API, and the screen handles what the user sees and interacts with. For the Cart endpoint, getting data by ID can be used to retrieve data based on a specific ID, such as a user ID, instead of getting all the available carts.
