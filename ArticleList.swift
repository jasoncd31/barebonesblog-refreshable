/**
 * ArticleList displays a list of articles, toggling between the list and a chosen article.
 */
import SwiftUI

struct ArticleList: View {
    @EnvironmentObject var auth: BareBonesBlogAuth
    @EnvironmentObject var articleService: BareBonesBlogArticle

    @Binding var requestLogin: Bool

    @State var articles: [Article]
    @State var error: Error?
    @State var fetching = false
    @State var writing = false
    
    private func loadArticles() async {
        do {
            let fetchedArticles = try await articleService.fetchArticles()
            await MainActor.run {
                self.articles = fetchedArticles
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if fetching {
                    ProgressView()
                } else {
                    List {
                        if let _ = error {
                            Section{
                                Text("Something went wrong... we wish we could say more")
                            }
                        } else if articles.isEmpty {
                            Section{
                                VStack(alignment: .center){
                                    Text("There are no articles.")
                                }
                            }
                        } else {
                            ForEach(articles) {article in
                                NavigationLink{
                                    ArticleDetail(article: article)
                                } label: {
                                    ArticleMetadata(article: article)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await loadArticles()
                    }
                }
            }
            .navigationTitle("Bare Bones Blog 🦴")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if auth.user != nil {
                        Button("New Article") {
                            writing = true
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if auth.user != nil {
                        Button("Sign Out") {
                            do {
                                try auth.signOut()
                            } catch {
                                // No error handling in the sample, but of course there should be
                                // in a production app.
                            }
                        }
                    } else {
                        Button("Sign In") {
                            requestLogin = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $writing) {
            ArticleEntry(articles: $articles, writing: $writing)
        }
        .task {
            fetching = true
            await loadArticles()
            fetching = false
        }
    }
}

struct ArticleList_Previews: PreviewProvider {
    @State static var requestLogin = false

    static var previews: some View {
        ArticleList(requestLogin: $requestLogin, articles: [])
            .environmentObject(BareBonesBlogAuth())

        ArticleList(requestLogin: $requestLogin, articles: [
            Article(
                id: "12345",
                title: "Preview",
                date: Date(),
                body: "Lorem ipsum dolor sit something something amet"
            ),

            Article(
                id: "67890",
                title: "Some time ago",
                date: Date(timeIntervalSinceNow: TimeInterval(-604800)),
                body: "Duis diam ipsum, efficitur sit amet something somesit amet"
            )
        ])
        .environmentObject(BareBonesBlogAuth())
        .environmentObject(BareBonesBlogArticle())
    }
}
