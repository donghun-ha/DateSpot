import SwiftUI

struct RestaurantDetailInfoView: View {
    @State var restaurant: Restaurant
    @EnvironmentObject var appState: AppState
    @StateObject private var ratingViewModel = RatingViewModel()
    @State private var rates: Int = 0 // StarRatingView와 바인딩할 별점 값
    @Binding var images :  UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(restaurant.name)
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                   print(appState.userEmail ?? "")
               }) {
                   NavigationLink(destination: RestaurantDetailMap(restaurants: $restaurant, images: $images, rates: $rates), label: {
                   HStack {
                       Image(systemName: "paperplane.fill")
                           .foregroundColor(.white)
                       Text("Navigate")
                           .foregroundColor(.white)
                   }
                   })
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(8)
               }

            }

            VStack(alignment: .leading) {
                StarRatingView(rating: Binding(
                    get: { rates },
                    set: { newRating in
                        rates = newRating
                    }
                )) { newRating in
                    Task {
                        if let email = appState.userEmail {
                            print("Updating rating to \(newRating)")
                            await ratingViewModel.restaurantupdateUserRating(for: email, restaurantName: restaurant.name, rating: newRating)
                            await ratingViewModel.restaurantfetchUserRating(for: email, restaurantName: restaurant.name)
                            rates = ratingViewModel.userRating ?? 0
                        } else {
                            print("User email is not available")
                        }
                    }
                }
                .frame(height: 20)
                .onAppear {
                    Task {
                        if let email = appState.userEmail {
                            await ratingViewModel.restaurantfetchUserRating(for: email, restaurantName: restaurant.name)
                            rates = ratingViewModel.userRating ?? 0
                        }
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("운영 시간: \(restaurant.operatingHour)")
                    .font(.subheadline)
            }

            HStack(spacing: 4) {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(restaurant.address)
                    .font(.subheadline)
            }

            if !restaurant.closedDays.isEmpty {
                Text("휴무일: \(restaurant.closedDays)")
                    .font(.subheadline)
            }
            if !restaurant.parking.isEmpty {
                Text("주차: \(restaurant.parking)")
                    .font(.subheadline)
            }
            if !restaurant.contactInfo.isEmpty {
                Text("연락처: \(restaurant.contactInfo)")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}
