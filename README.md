![alt [version]](https://img.shields.io/github/v/release/neothXT/Snowdrop) ![alt spm available](https://img.shields.io/badge/SPM-available-green) ![alt cocoapods available](https://img.shields.io/badge/CocoaPods-unavailable-red) ![alt carthage unavailable](https://img.shields.io/badge/Carthage-unavailable-red) ![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg) ![Concurrency Safe](https://img.shields.io/badge/Concurrency-Safe-brightgreen.svg)

![alt text](https://github.com/neothXT/Snowdrop/blob/main/Snowdrop_Logo.png)

# Snowdrop

Meet **Snowdrop** - type-safe, easy to use framework powered by Swift Macros created to let you build and maintain complex network requests with ease.

> **🎉 Swift 6.0 支持！** Snowdrop 现已完全支持 Swift 6.0，具备完整的编译时并发安全检查。查看 [迁移指南](./SWIFT6_MIGRATION_GUIDE.md) 了解详情。

## Navigation

- [Installation](#installation)
- [Swift 6.0 Support](#swift-60-support)
- [Key Functionalities](#key-functionalities)
- [Basic Usage](#basic-usage)
    - [Service Declaration](#service-declaration)
    - [Request Execution](#request-execution)
- [Advanced Usage](#advanced-usage)
    - [Default JSON Decoder](#default-json-decoder)
    - [SSL/Certificate Pinning](#sslcertificate-pinning)
    - [Body Argument](#body-argument)
    - [File Upload using form-data](#file-upload-using-form-data)
    - [Query Parameters](#query-parameters)
    - [Arguments' Default Values](#arguments-default-values)
    - [Interceptors](#interceptors)
    - [Mockable](#mockable)
    - [JSON Injection](#json-injection)
    - [Verbose](#verbose)
- [Acknowledgements](#acknowledgements)

## Installation

Snowdrop is available via SPM. It works with iOS Deployment Target 14.0 or later and macOS Deployment Target 11 or later.

### Requirements

- **Swift**: 6.0+
- **iOS**: 14.0+
- **macOS**: 11.0+
- **Xcode**: 16.0+ (recommended)

## Swift 6.0 Support

Snowdrop 完全支持 Swift 6.0，具备以下特性：

- ✅ **编译时数据竞争检查** - 在编译时就能发现并发问题
- ✅ **完整的 Sendable 支持** - 所有公开 API 都是并发安全的
- ✅ **严格并发检查** - 启用 `StrictConcurrency` 特性
- ✅ **类型安全保证** - 更强的类型安全检查

### 迁移资源

如果你正在从 Swift 5.9 升级到 6.0，请查阅以下文档：

- 📖 [完整迁移指南](./SWIFT6_MIGRATION_GUIDE.md) - 详细的迁移步骤和技术细节
- 🚀 [快速参考指南](./SWIFT6_QUICK_REFERENCE.md) - 常见问题和最佳实践
- 📝 [更新日志](./CHANGELOG_SWIFT6.md) - 所有变化的详细记录

### 主要变化

在 Swift 6.0 版本中，有几个小的 API 变化需要注意：

1. **SnowdropErrorDetails.headers** 现在是 `[String: String]?` 类型（之前是 `[AnyHashable: Any]?`）
2. **QueryItem.value** 必须是 `Sendable` 类型
3. **RequestHandler 和 ResponseHandler** 闭包现在是 `@Sendable`

大多数代码无需修改即可工作。查看 [快速参考指南](./SWIFT6_QUICK_REFERENCE.md) 了解更多细节。

## Key Functionalities

- Type-safe service creation with `@Service` macro
- Support for various request method types such as
    - `@GET`
    - `@POST`
    - `@PUT`
    - `@DELETE`
    - `@PATCH`
    - `@CONNECT`
    - `@HEAD`
    - `@OPTIONS`
    - `@QUERY`
    - `@TRACE`
- SSL/Certificate pinning
- Interceptors
- Mockable

## Basic Usage

### Service Declaration

Creating network services with Snowdrop is really easy. Just declare a protocol along with its functions. 

```Swift
@Service
protocol MyEndpoint {

    @GET(url: "/posts")
    @Headers(["X-DeviceID": "testSim001"])
    func getAllPosts() async throws -> [Post]
}
```

If your request includes some dynamic values, such as `id`, you can add it to your path wrapping it with `{}`. Snowdrop will automatically bind your function declaration's arguments with those you include in request's path.

```Swift
@GET(url: "/posts/{id}")
func getPost(id: Int) async throws -> Post
```

### Request Execution

Upon expanding macros, Snowdrop creates a class `MyEndpointService` which implements `MyEndpoint` protocol and generates all the functions you declared.

```Swift
class MyEndpointService: MyEndpoint {
    func getAllPosts() async throws -> [Post] {
        // auto-generated body
    }
    
    func getPost(id: Int) async throws -> Post {
        // auto-generated body
    }
}
```

**Please note that if your service protocol already have "Service" keyword like `MyEndpointService`, macro will then generate the class named `MyEndpointServiceImpl` instead.**

To send requests, just initialize `MyEndpointService` instance and call function corresponding to the request you want to execute.

```Swift
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
let post = try await service.getPost(id: 7)
```

## Advanced Usage

### Default JSON Decoder

If you need to change default json decoder, you can set your own decoder when creating an instance of your service.

```Swift
let decoder = CustomJSONDecoder()
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!, decoder: decoder)
```

#### SSL/Certificate Pinning

Snowdrop offers SSL/Certificate pinning functionality when executing network requests. You can turn it on/off when creating an instance of your service. You can also determine urls that should be excluded from pinning.

```Swift
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!, pinningMode: .ssl, urlsExcludedFromPinning: ["https://my-endpoint.com/about"])
```

### Body Argument

If you want to put some encodable object as a body of your request, you can either put it in your declaration as "body" argument or - if you want to use another name - use `@Body` macro like:

```Swift
@POST(url: "/posts")
@Body("model")
func addPost(model: Post) async throws -> Data
```

### File Upload using form-data

If you want to declare service's function that sends some file to the server as `multipart/form-data`, use `@FileUpload` macro. It'll automatically add `Content-Type: multipart/form-data` to the request's headers and extend the list of your function's arguments with `_payloadDescription: PayloadDescription` which you should then use to provide information such as `name`, `fileName` and `mimeType`.
For mime types such as jpeg, png, gif, tiff, pdf, vnd, plain, octetStream, you don't have to provide `PayloadDescription`. Snowdrop can automatically recognize them and create `PayloadDescription` for you.

```Swift
@Service
protocol MyEndpoint {

    @FileUpload
    @Body("image")
    @POST(url: "/uploadAvatar/")
    func uploadImage(_ image: UIImage) async throws -> Data
}

let payload = PayloadDescription(name: "avatar", fileName: "filename.jpeg", mimeType: "image/jpeg")
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
_ = try await service.uploadImage(someImage, _payloadDescription: payload)
```

### Query Parameters

With Snowdrop, you can pass your query params in two ways.

First one is to use `@QueryParams` macro. To inform which arguments of your func are supposed to be query params, put them in array like this:

```Swift
@Service
protocol MyEndpoint {
    @GET(url: "/posts/{id}")
    @QueryParams(["author"])
    func getPost(id: Int, author: String) async throws -> Post
}

let authorName = "John Smith"
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
let post = try await service.getPost(id: 7, author: authorName)
```

Alternatively, upon expanding macros, Snowdrop adds argument `_queryItems: [QueryItem]` to every service's function. Use it like this:

```Swift
@Service
protocol MyEndpoint {
    @GET(url: "/posts/{id}")
    func getPost(id: Int) async throws -> Post
}

let authorName = "John Smith"
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!)
let post = try await service.getPost(id: 7, _queryItems: [.init(key: "author", value: authorName)])
```

### Arguments' Default Values

Snowdrop allows you to define custom values for your arguments. Let's say your path includes `{id}` argument. As you already know by now, Snowdrop automatically associates it with `id` argument of your `func` declaration. If you want it to have default value equal "3", do it like: `{id=3}`. Be careful though as Snowdrop won't check if your default value's type conforms to the declaration.  
When inserting `String` default values such as {name="Some name"}, it is strongly recommended to use `Raw String` like `@GET(url: #"/authors/{name="John Smith"}"#)`.

### Interceptors

Each service provides two methods to add interception blocks - `addBeforeSendingBlock` and `addOnResponseBlock`. Both accept arguments such as `path` of type `String` and `block` which is closure.

To add `addBeforeSendingBlock` or `addOnResponseBlock` for a requests matching certain path, use regular expressions like:

```Swift
service.addBeforeSendingBlock(for: "my/path/[0-9]{1,}/content") { urlRequest in
    // some operations
    return urlRequest
}
```

To add `addBeforeSendingBlock` or `addOnResponseBlock` for ALL requests, do it like:

```Swift
service.addOnResponseBlock { data, httpUrlResponse in
    // some operations
    return data
}
```

**Note that if you add interception block for a certain request path, general interceptors will be ignored.**

### Mockable

If you'd like to create mockable version of your service, Snowdrop got you covered. Just add `@Mockable` macro to your service declaration like

```Swift
@Service
@Mockable
protocol Endpoint {
    @Get("/path")
    func getPosts() async throws -> [Posts]
}
```

Snowdrop will automatically create a `EndpointServiceMock` class with all the properties `Service` should have and additional properties such as `getPostsResult` to which you can assign value that should be returned.

#### Sample usage:

```Swift
func testEmptyArrayResult() async throws {
    let mock = EndpointServiceMock(baseUrl: URL(string: "https://some.url")!
    mock.getPostsResult = .success([])

    let result = try await mock.getPosts()
    XCTAssertTrue(result.isEmpty)
}
```

**Note that mocked methods will directly return stubbed result without accessing Snowdrop.Core so your beforeSend and onResponse blocks won't be called.**

### JSON Injection

If you'd like to test your service against mocked JSONs, you can easily do it. Just make sure you got your JSON mock somewhere in your project files, then instantiate your service and determine for which request your mock should be injected like in the example below.

```Swift
func testJSONMockInjectsion() async throws {
    let service = MyEndpointService(baseUrl: someBaseURL)
    service.testJSONDictionary = ["users/123/info": "MyJSONMock"]
    
    let result = try await service.getUserInfo(id: 123)
    XCTAssertTrue(result.firstName, "JSON")
    XCTAssertTrue(result.lastName, "Bourne")
}
```

### Verbose

If you'd like to get see logs from Snowdrop, use `verbose` flag when creating new instance of your service.

```Swift
let service = MyEndpointService(baseUrl: URL(string: "https://my-endpoint.com")!, verbose: true)
```

## Acknowledgements

Retrofit was an inspiration for Snowdrop.
