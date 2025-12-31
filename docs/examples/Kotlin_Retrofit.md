# Android (Kotlin + Retrofit) 代码示例

## 📋 概述

本文档提供 Android 平台使用 Kotlin 和 Retrofit 框架调用 API 的完整示例。

---

## 1. 项目配置

### 添加依赖

**build.gradle (Module: app)**:
```kotlin
dependencies {
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.11.0")
}
```

---

## 2. 数据模型定义

### API 接口定义

```kotlin
interface VideoAllApi {
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<LoginResponse>

    @GET("content/")
    suspend fun getContentList(
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 20,
        @Query("platform") platform: String? = null
    ): Response<ContentListResponse>

    @POST("content/parse")
    suspend fun parseContent(@Body request: ParseRequest): Response<ParseResponse>

    @GET("users/me")
    suspend fun getCurrentUser(): Response<UserResponse>

    @PUT("users/me")
    suspend fun updateCurrentUser(@Body request: UpdateUserRequest): Response<UserResponse>
}
```

### 数据类定义

```kotlin
// 认证相关
data class LoginRequest(
    val username: String,
    val password: String
)

data class LoginResponse(
    val message: String,
    val data: LoginData
)

data class LoginData(
    val user: User,
    val token: String
)

data class User(
    val id: String,
    val username: String,
    val email: String?,
    val role: String,
    val is_active: Boolean
)

// 内容相关
data class ParseRequest(
    val link: String
)

data class ParseResponse(
    val message: String,
    val title: String,
    val author: String,
    val platform: String,
    val media_type: String,
    val cover_url: String
)

data class ContentListResponse(
    val message: String,
    val data: ContentListData
)

data class ContentListData(
    val list: List<Content>,
    val total: Int,
    val page: Int,
    val page_size: Int
)

data class Content(
    val id: String,
    val title: String,
    val author: String,
    val platform: String,
    val cover_url: String,
    val like_count: Int
)

// 用户更新
data class UpdateUserRequest(
    val username: String? = null
)
```

---

## 3. Retrofit 配置

### 创建 Retrofit 实例

```kotlin
object RetrofitClient {
    private const val BASE_URL = "http://localhost:3000/api/v1/"
    
    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor())
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .build()
    
    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    val api: VideoAllApi = retrofit.create(VideoAllApi::class.java)
}
```

### 认证拦截器

```kotlin
class AuthInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val token = TokenManager.getToken()
        
        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .build()
        
        return chain.proceed(request)
    }
}
```

### Token 管理

```kotlin
object TokenManager {
    private const val PREFS_NAME = "auth_prefs"
    private const val KEY_TOKEN = "token"
    private const val KEY_USER = "user"
    
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    fun saveToken(token: String) {
        prefs.edit().putString(KEY_TOKEN, token).apply()
    }
    
    fun getToken(): String? {
        return prefs.getString(KEY_TOKEN, null)
    }
    
    fun clearToken() {
        prefs.edit()
            .remove(KEY_TOKEN)
            .remove(KEY_USER)
            .apply()
    }
}
```

---

## 4. 完整使用示例

### 登录流程

```kotlin
class LoginViewModel : ViewModel() {
    private val _loginState = MutableStateFlow<UiState<User>>(UiState.Idle)
    val loginState: StateFlow<UiState<User>> = _loginState
    
    fun login(username: String, password: String) {
        viewModelScope.launch {
            _loginState.value = UiState.Loading
            
            try {
                val response = RetrofitClient.api.login(
                    LoginRequest(username, password)
                )
                
                if (response.isSuccessful && response.body() != null) {
                    val data = response.body()!!.data
                    TokenManager.saveToken(data.token)
                    _loginState.value = UiState.Success(data.user)
                } else {
                    _loginState.value = UiState.Error("登录失败")
                }
            } catch (e: Exception) {
                _loginState.value = UiState.Error(e.message ?: "未知错误")
            }
        }
    }
}
```

### 获取内容列表

```kotlin
class ContentViewModel : ViewModel() {
    private val _contentList = MutableStateFlow<List<Content>>(emptyList())
    val contentList: StateFlow<List<Content>> = _contentList
    
    fun loadContents(page: Int = 1) {
        viewModelScope.launch {
            try {
                val response = RetrofitClient.api.getContentList(page = page)
                
                if (response.isSuccessful && response.body() != null) {
                    val contents = response.body()!!.data.list
                    _contentList.value = contents
                }
            } catch (e: Exception) {
                // 处理错误
            }
        }
    }
}
```

### 解析内容

```kotlin
suspend fun parseContent(link: String): ParseResponse {
    val response = RetrofitClient.api.parseContent(ParseRequest(link))
    
    if (!response.isSuccessful) {
        throw Exception(response.code().toString())
    }
    
    return response.body() ?: throw Exception("解析失败")
}
```

---

## 5. 错误处理

### 统一错误处理

```kotlin
sealed class UiState<out T> {
    object Idle : UiState<Nothing>()
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
```

---

**最后更新**: 2025-12-28
