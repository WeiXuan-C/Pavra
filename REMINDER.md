| 🧠 概念                      | 🧩 React 中的名称                   | 🧱 Flutter 中的名称                               | 💬 说明                               |
| ---------------------------- | ----------------------------------- | ------------------------------------------------  | ------------------------------------- |
| **UI 构建单元**               | Component                       | Widget                                        | 一切 UI 元素都是它（Button、Text、Container…） |
| **无状态组件**                | Function Component              | StatelessWidget                               | 只负责渲染，不持有状态                         |
| **有状态组件**                | Class Component（或 useState）     | StatefulWidget                                | 可以使用内部状态、setState() 更新              |
| **Props（传参）**            | props                           | 构造函数参数                                        | 用来从父组件传值到子组件                        |
| **State（状态）**            | useState / this.state           | State<T> 类 + setState()                       | 控制组件内部变化                            |
| **Component Tree**         | Virtual DOM Tree                | Widget Tree                                   | UI 层级结构（所有东西都是 Widget）              |
| **Children**               | props.children                  | children: [...]                               | 子组件（嵌套结构）                           |
| **Conditional Render**     | `{ condition && <View /> }`     | `if (...) ... else ...` / 三元运算符               | 根据条件显示不同 UI                         |
| **List 渲染**                | `array.map()`                   | `ListView.builder()` / `.map()`               | 用循环渲染多个组件                           |
| **Event Handling**         | onClick, onChange               | onPressed, onTap, onChanged                   | Flutter 也通过回调函数处理事件                 |
| **Lifecycle**              | componentDidMount, useEffect    | initState(), dispose(), didUpdateWidget()     | 控制组件生命周期逻辑                          |
| **Context（全局状态）**          | React Context                   | InheritedWidget / Provider                    | 提供跨层数据共享                            |
| **State Management**       | Redux, MobX, Zustand            | Provider, Riverpod, Bloc, GetX                | 状态管理框架                              |
| **Navigation**             | React Router                    | Navigator / GoRouter / auto_route             | 控制页面跳转                              |
| **Styling**                | CSS / styled-components         | ThemeData / style 参数 / custom widgets         | Flutter 没有 CSS，一切通过 Widget 层配置      |
| **Animations**             | CSS transitions / Framer Motion | AnimationController / AnimatedWidget / Lottie | Flutter 自带动画系统                      |
| **Reusable Components**    | Shared components folder        | widgets/ 文件夹                                  | 自己写的可复用 UI 组件                       |
| **3rd-party UI Lib**       | npm install component           | pub.dev 包（import package）                     | 一样可以引入外部 UI 组件                      |
| **App Root**               | index.js / App.js               | main.dart / runApp(MyApp())                   | 应用入口文件                              |
| **Component Props Typing** | PropTypes / TypeScript          | Dart 类型系统                                     | 参数类型在构造函数中定义                        |
| **JSX 语法**                | `<div>Hello</div>`              | `Container(child: Text('Hello'))`             | Flutter 用嵌套函数式语法构建 UI               |
| **Hot Reload**             | React Fast Refresh              | Flutter Hot Reload                            | 两者都有快速刷新机制                          |
| **Dependency Management**  | npm / yarn                      | pubspec.yaml / flutter pub get                | 管理依赖包                               |
| **API 调用**                 | fetch / axios                   | http / dio / supabase_flutter                 | 数据请求层                               |