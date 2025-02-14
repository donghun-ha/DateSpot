import SwiftUI

struct RestaurantSectionView: View {
    @StateObject var viewModel = RestaurantViewModel() // ViewModel 초기화
    @State private var userLocation: (lat: Double, lng: Double) = (37.5255100592, 127.0367640978) // 기본 위치 (서울)
    @StateObject var mapViewModel = TabMapViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !mapViewModel.authorization {
                Text("위치 제공 동의가 필요합니다.")
            }
            else{
                sectionHeader
                restaurantScrollView
            }
        }
        .onAppear {
            if mapViewModel.authorization{
                Task {
                    await viewModel.fetchNearbyPlaces(
                        lat: (mapViewModel.userLocation?.coordinate.latitude)!,
                        lng: (mapViewModel.userLocation?.coordinate.longitude)!,
                        radius: 1000
                    )
                }
            }
//            else{
//                Task {
//                    await viewModel.fetchNearbyPlaces(
//                        lat: (userLocation.lat),
//                        lng: (userLocation.lng),
//                        radius: 1000
//                    )
//                }
//                
//            }
        }
    }

    private var sectionHeader: some View {
        Text("맛집")
            .font(.title)
            .fontWeight(.bold)
            .padding(.horizontal)
    }

    private var restaurantScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(viewModel.nearbyRestaurants.prefix(5)) { restaurant in
                    restaurantCard(for: restaurant)
                }
            }
            .padding(.horizontal)
        }
    }

    private func restaurantCard(for restaurant: Restaurant) -> some View {
        NavigationLink(destination: RestaurantDetailView(name: restaurant.name)) {
            createCardView(for: restaurant)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                // 스크롤될 때마다 동적으로 데이터 로드
                await viewModel.fetchNearbyRestaurants(
                    lat: (mapViewModel.userLocation?.coordinate.latitude)!,
                    lng: (mapViewModel.userLocation?.coordinate.longitude)!,
                    radius: 1000
                )
            }
        }
    }

    private func createCardView(for restaurant: Restaurant) -> some View {
        ZStack {
            if let image = viewModel.homeimage[restaurant.name] {
                CardView(
                    image: image,
                    category: restaurant.parking,
                    heading: restaurant.name,
                    author: restaurant.address
                )
                .frame(width: 300, height: 300)
            } else {
                CardView(
                    image: UIImage(systemName: "photo"), // 기본 이미지
                    category: restaurant.parking,
                    heading: restaurant.name,
                    author: restaurant.address
                )
                .frame(width: 300, height: 300)
                .onAppear {
                    Task {
                        if viewModel.homeimage[restaurant.name] == nil {
                            await viewModel.fetchFirstImage(for: restaurant.name)
                        }
                    }
                }
            }
        }
    }
}

// ViewModel과 CardView, DetailView는 기존 프로젝트 코드와 동일하다고 가정합니다.
