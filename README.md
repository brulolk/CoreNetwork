
---

# 📦 CoreNetwork

Camada de networking moderna, leve e tipada para iOS/macOS baseada em **Swift Concurrency (async/await)**.

Projetada para simplificar chamadas HTTP, WebSocket e transferências em background com foco em **clareza, testabilidade e escalabilidade**.

---

## ✨ Features

* Async/Await nativo
* Tipagem forte com `Decodable`
* Retry automático configurável
* Tratamento de erros padronizado
* Headers globais
* Upload/Download em background
* WebSocket com `AsyncStream`
* Fácil de testar
* Estrutura baseada em `Endpoint`

---

## ⚙️ Requisitos

* iOS 15+
* macOS 12+
* Swift 6+

---

## 📥 Instalação

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/seu-repo/CoreNetwork.git", from: "1.0.0")
]
```

---

## 🚀 Uso rápido

### 1. Criando um Endpoint

```swift
struct GetUsersEndpoint: Endpoint {
    var baseURL: String = "https://api.example.com"
    var path: String = "/users"
    var method: HTTPMethod = .get
}
```

---

### 2. Fazendo uma requisição

```swift
let client = NetworkClient()

let response = try await client.request(
    endpoint: GetUsersEndpoint(),
    responseType: [User].self
)

print(response.data)
```

---

### 3. Acessando headers e status code

```swift
print(response.statusCode)

let pagination = response.valueForHeader("x-pagination-count")
```

---

## 🔁 Retry automático

```swift
let response = try await client.request(
    endpoint: endpoint,
    responseType: Model.self,
    maxRetries: 3
)
```

---

## 🌐 Headers globais

```swift
await NetworkConfig.shared.addGlobalHeader(
    name: "Authorization",
    value: "Bearer token"
)
```

---

## 🧠 Tratamento de erros

```swift
do {
    let response = try await client.request(...)
} catch let error as NetworkError {
    switch error {
    case .invalidURL:
        print("Invalid URL")
    case .serverError(let statusCode, _):
        print("Server error: \(statusCode)")
    case .timeout:
        print("Timeout")
    case .noInternet:
        print("No internet")
    default:
        break
    }
}
```

---

## 🔄 Upload / Download em Background

```swift
try BackgroundTransferClient.shared.upload(
    fileURL: fileURL,
    to: endpoint
)

try BackgroundTransferClient.shared.download(
    from: endpoint
)
```

---

## 🔌 WebSocket

### Conectar

```swift
let socket = WebSocketClient()
try await socket.connect(to: "wss://example.com/socket")
```

### Enviar mensagem

```swift
try await socket.send(message: "Hello")
```

### Escutar mensagens

```swift
for await message in socket.listen() {
    print(message)
}
```

---

## 🧪 Testabilidade

A biblioteca foi projetada para ser facilmente testável através da injeção de `URLSession`.

Você pode criar uma sessão customizada com `URLProtocol` para mockar respostas:

```swift
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]

let session = URLSession(configuration: config)
let client = NetworkClient(session: session)
```

---

## 🧰 Helpers

### Encode de Body

```swift
let data = endpoint.encodeBody(model)
```

ou

```swift
let data = endpoint.encodeBody(dictionary: ["key": "value"])
```

---

## 📌 Boas práticas

* Criar um `Endpoint` por recurso
* Centralizar autenticação via `NetworkConfig`
* Tratar erros explicitamente
* Usar retry apenas para falhas transitórias

---

## 🔒 Contribuição

Esta biblioteca é mantida internamente.
Sugestões e melhorias podem ser propostas via issue.

---

## 📄 Licença

Uso livre para integração em projetos.
