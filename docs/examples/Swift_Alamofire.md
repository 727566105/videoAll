# iOS (Swift + Alamofire) 代码示例

## 📋 概述

本文档提供 iOS 平台使用 Swift 和 Alamofire 框架调用 API 的完整示例。

---

## 1. 项目配置

### 添加依赖

**Podfile**:
```ruby
pod 'Alamofire', '~> 5.8'
```

然后运行：
```bash
pod install
```

---

## 2. 网络管理器

### NetworkManager 实现

```swift
import Alamofire
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:3000/api/v1"
    private var session: Session!
    
    private init() {
        let interceptor = AuthInterceptor()
        session = Session(interceptor: interceptor)
    }
    
    // MARK: - 认证相关
    func login(email: String, password: String, 
               completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        let parameters = ["email": email, "password": "password"]
        
        session.request("\(baseURL)/auth/login",
                       method: .post,
                       parameters: parameters,
                       encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: LoginResponse.self) { response in
                switch response.result {
                case .success(let data):
                    // 保存 Token
                    if let token = data.data.token {
                        UserDefaults.standard.set(token, forKey: "token")
                    }
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func getCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        session.request("\(baseURL)/users/me")
            .validate()
            .responseDecodable(of: UserResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data.data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - 内容相关
    func parseContent(link: String, 
                     completion: @escaping (Result<ParseResponse, Error>) -> Void) {
        let parameters = ["link": link]
        
        session.request("\(baseURL)/content/parse",
                       method: .post,
                       parameters: parameters,
                       encoder: JSONParameterEncoder.default)
            .validate()
            .responseDecodable(of: ParseResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func getContentList(page: Int = 1, 
                        completion: @escaping (Result<[Content], Error>) -> Void) {
        let parameters = [
            "page": page,
            "page_size": 20
        ]
        
        session.request("\(baseURL)/content/",
                       method: .get,
                       parameters: parameters)
            .validate()
            .responseDecodable(of: ContentListResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data.data.list))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
```

### 认证拦截器

```swift
class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, 
               completion: @escaping (URLRequest) -> Void) {
        var request = urlRequest
        
        if let token = UserDefaults.standard.string(forKey: "token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        completion(request)
    }
}
```

---

## 3. 数据模型

### Codable 模型定义

```swift
// MARK: - 通用响应
struct APIResponse<T: Decodable>: Decodable {
    let message: String
    let data: T
}

// MARK: - 认证模型
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let message: String
    let data: LoginData
}

struct LoginData: Decodable {
    let user: User
    let token: String
}

struct User: Codable {
    let id: String
    let username: String
    let email: String?
    let role: String
    let is_active: Bool
    let created_at: String
    let updated_at: String
}

// MARK: - 内容模型
struct ParseRequest: Encodable {
    let link: String
}

struct ParseResponse: Decodable {
    let message: String
    let title: String
    let author: String
    let platform: String
    let media_type: String
    let cover_url: String
}

struct Content: Codable {
    let id: String
    let title: String
    let author: String
    let platform: String
    let cover_url: String
    let like_count: Int
    let created_at: String
}

struct ContentListResponse: Decodable {
    let message: String
    let data: ContentListData
}

struct ContentListData: Decodable {
    let list: [Content]
    let total: Int
    let page: Int
    let page_size: Int
}
```

---

## 4. 使用示例

### 登录

```swift
import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text else {
            return
        }
        
        NetworkManager.shared.login(email: email, password: password) { result in
            switch result {
            case .success(let response):
                print("登录成功: \(response.data.user.username)")
                // 跳转到主页
                self.performSegue(withIdentifier: "showMain", sender: self)
            case .failure(let error):
                print("登录失败: \(error.localizedDescription)")
                self.showErrorAlert(message: error.localizedDescription)
            }
        }
    }
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "错误",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### 获取内容列表

```swift
import UIKit

class ContentListViewController: UIViewController {
    var contents: [Content] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContents()
    }
    
    func loadContents() {
        NetworkManager.shared.getContentList { [weak self] result in
            switch result {
            case .success(let contents):
                self?.contents = contents
                self?.tableView.reloadData()
            case .failure(let error):
                print("加载失败: \(error)")
            }
        }
    }
}
```

---

## 5. Token 管理

### TokenManager

```swift
class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "token"
    private let userKey = "user"
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }
    
    var isLoggedIn: Bool {
        return getToken() != nil
    }
}
```

---

## 6. 错误处理

### 自定义错误类型

```swift
enum APIError: Error, LocalizedError {
    case networkError
    case authenticationError
    case invalidResponse
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "网络连接失败"
        case .authenticationError:
            return "认证失败，请重新登录"
        case .invalidResponse:
            return "服务器响应无效"
        case .serverError(let message):
            return message
        }
    }
}
```

---

**最后更新**: 2025-12-28
