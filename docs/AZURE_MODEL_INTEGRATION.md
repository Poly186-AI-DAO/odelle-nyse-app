# Azure Deployed Model Integration Guide

This guide details how to integrate an Azure-deployed machine learning model into the Flutter application.

## Overview

The standard approach for communicating with Azure Machine Learning (Azure ML) models from a Flutter app is via **REST API**. When you deploy a model in Azure ML as an "Online Endpoint", it exposes a stable URL that accepts HTTP requests (typically POST) and returns predictions.

## Prerequisites

1.  **Azure ML Endpoint**: A model deployed to an Azure Machine Learning Online Endpoint.
2.  **Endpoint URL**: The HTTPS URL for the deployed model (e.g., `https://<your-endpoint>.inference.ml.azure.com/score`).
3.  **API Key/Token**: The authentication key (Primary/Secondary) or a valid Azure AD token for the endpoint.

## Integration Steps

### 1. Add Dependencies

Ensure your `pubspec.yaml` includes the `http` package for making network requests.

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0  # Check for the latest version
```

### 2. Create the API Service

Create a service class (e.g., `AzureModelService`) to handle the communication.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AzureModelService {
  final String endpointUrl;
  final String apiKey;

  AzureModelService({
    required this.endpointUrl,
    required this.apiKey,
  });

  Future<Map<String, dynamic>> getPrediction(Map<String, dynamic> inputData) async {
    try {
      final uri = Uri.parse(endpointUrl);
      
      // Azure ML endpoints typically expect a specific JSON structure.
      // often wrapped in "data" or "input_data" keys depending on the model signature.
      // Example for a standard Scikit-learn or similar model:
      // {
      //   "input_data": {
      //     "columns": ["feature1", "feature2"],
      //     "index": [0],
      //     "data": [[value1, value2]]
      //   }
      // }
      //
      // Adjust the body structure below to match your specific model's expectation.
      
      final body = jsonEncode(inputData);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          // 'azureml-model-deployment': 'blue', // Optional: Target specific deployment
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load prediction. Status: ${response.statusCode}. Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error calling Azure endpoint: $e');
    }
  }
}
```

### 3. Usage Example

```dart
void testModel() async {
  final service = AzureModelService(
    endpointUrl: 'https://my-model-endpoint.inference.ml.azure.com/score',
    apiKey: 'MY_SECRET_API_KEY',
  );

  // Structure this data according to your model's schema
  final input = {
    "data": [
      [1.5, 2.3, 0.5] // Example features
    ]
  };

  try {
    final result = await service.getPrediction(input);
    print('Model Prediction: $result');
  } catch (e) {
    print('Error: $e');
  }
}
```

## Best Practices

*   **Security**: Never hardcode API keys in your client-side Flutter code. Use a backend proxy or Azure Functions to hide the keys, or use secure storage and strict CORS/authentication policies if calling directly (not recommended for production keys).
*   **Error Handling**: Handle timeouts, network failures, and 4xx/5xx server errors gracefully.
*   **Data Formatting**: Be precise with the JSON structure. Azure ML expects the input JSON to match the input schema defined during deployment (e.g., Swagger/OpenAPI spec of the endpoint).
*   **Async/Await**: Always ensure network calls do not block the main UI thread.

## Resources

*   [Consume an online endpoint (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-consume-online-endpoint)
*   [Flutter `http` package](https://pub.dev/packages/http)
