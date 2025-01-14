//import SwiftUI
//
//struct PlaceSectionView: View {
//    let places: [PlaceData]
//    @ObservedObject var viewModel: PlaceViewModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("명소")
//                .font(.title)
//                .fontWeight(.bold)
//                .padding(.horizontal)
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack(spacing: 20) {
//                    ForEach(Array(places.prefix(20)), id: \.name) { place in
//                        NavigationLink(
//                            destination: DetailView(restaurantName: place.name) // 클릭 시 DetailView로 이동
//                        ) {
//                            ZStack {
//                                if let image = viewModel.images[place.name] {
//                                    CardView(
//                                        image: image,
//                                        category: place.parking,
//                                        heading: place.name,
//                                        author: place.address
//                                    )
//                                    .frame(width: 300)
//                                } else {
//                                    CardView(
//                                        image: UIImage(systemName: "photo"),
//                                        category: place.parking,
//                                        heading: place.name,
//                                        author: place.address
//                                    )
//                                    .frame(width: 300)
//                                    .onAppear {
//                                        Task {
//                                            await viewModel.fetchFirstImage(for: place.name)
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                        .buttonStyle(PlainButtonStyle()) // 기본 스타일 제거
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}
//
import SwiftUI

struct PlaceSectionView: View {
    let places: [PlaceData]
    @ObservedObject var viewModel: PlaceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("명소")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(Array(places.prefix(20)), id: \.name) { place in
                        placeCard(for: place)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // 개별 PlaceCard를 생성하는 메서드
    private func placeCard(for place: PlaceData) -> some View {
        NavigationLink(
            destination: DetailView(restaurantName: place.name) // 클릭 시 DetailView로 이동
        ) {
            ZStack {
                if let image = viewModel.images[place.name] {
                    CardView(
                        image: image,
                        category: place.parking,
                        heading: place.name,
                        author: place.address
                    )
                    .frame(width: 300)
                } else {
                    CardView(
                        image: UIImage(systemName: "photo"), // 기본 이미지
                        category: place.parking,
                        heading: place.name,
                        author: place.address
                    )
                    .frame(width: 300)
                    .onAppear {
                        Task {
                            await viewModel.fetchImage(for: place.name)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle()) // 기본 스타일 제거
    }
}
