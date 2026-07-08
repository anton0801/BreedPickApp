//
//  BreedDatabase.swift
//  BreedPick
//
//  Seed catalogue of chicken breeds with believable real-world profiles.
//  Stats are 1...5 unless noted. Used by the match engine and every screen.
//

import Foundation
import UserNotifications
import UIKit

enum BreedDatabase {

    static let all: [Breed] = [
        Breed(id: "rhode-island-red", name: "Rhode Island Red", purpose: .dual,
              eggsPerYear: 260, eggColor: .brown, eggSize: .large, weightLb: 6.5,
              coldHardiness: 4, heatTolerance: 4, calmness: 3, friendliness: 3,
              flightiness: 2, noise: 3, broodiness: 2, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Reliable steady layer", "Tough and adaptable", "Great beginner bird"],
              cons: ["Roosters can be bossy", "Not very cuddly"],
              appearance: "Deep rust-red plumage with a confident upright stance.",
              summary: "The workhorse of the backyard flock — dependable brown eggs in almost any climate.",
              accentHex: "C2683A"),

        Breed(id: "white-leghorn", name: "White Leghorn", purpose: .eggs,
              eggsPerYear: 300, eggColor: .white, eggSize: .large, weightLb: 4.5,
              coldHardiness: 2, heatTolerance: 5, calmness: 2, friendliness: 2,
              flightiness: 5, noise: 4, broodiness: 1, confinementTolerance: 2, foraging: 5,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Egg machine — white eggs", "Excellent in heat", "Efficient feeder"],
              cons: ["Flighty and loud", "Large comb frostbites in cold"],
              appearance: "Bright white feathers with a big floppy red comb.",
              summary: "The classic white-egg layer. Unbeatable output but needs space and warm winters.",
              accentHex: "8A8A3C"),

        Breed(id: "plymouth-rock", name: "Barred Plymouth Rock", purpose: .dual,
              eggsPerYear: 250, eggColor: .brown, eggSize: .large, weightLb: 7.0,
              coldHardiness: 5, heatTolerance: 3, calmness: 4, friendliness: 4,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Calm and friendly", "Cold hardy", "Good dual-purpose size"],
              cons: ["Average summer layer"],
              appearance: "Striking black-and-white barred feathers, broad friendly body.",
              summary: "A family favourite: docile, hardy and a steady brown-egg layer through winter.",
              accentHex: "E0982A"),

        Breed(id: "buff-orpington", name: "Buff Orpington", purpose: .dual,
              eggsPerYear: 200, eggColor: .brown, eggSize: .large, weightLb: 8.0,
              coldHardiness: 5, heatTolerance: 2, calmness: 5, friendliness: 5,
              flightiness: 1, noise: 2, broodiness: 4, confinementTolerance: 5, foraging: 3,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Wonderful with children", "Very cold hardy", "Great broody mother"],
              cons: ["Can overheat", "Eats well — heavy bird"],
              appearance: "Fluffy golden plumage, round and teddy-bear soft.",
              summary: "The gentle giant. Calm, broody and cold-proof — perfect for families and small yards.",
              accentHex: "F4BE5A"),

        Breed(id: "australorp", name: "Australorp", purpose: .dual,
              eggsPerYear: 290, eggColor: .brown, eggSize: .large, weightLb: 6.5,
              coldHardiness: 4, heatTolerance: 4, calmness: 4, friendliness: 4,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Record-setting layer", "Calm and quiet", "Handles heat and cold"],
              cons: ["Glossy black shows dust"],
              appearance: "Glossy black feathers with a green sheen, soft dark eyes.",
              summary: "A near-perfect all-rounder: huge egg numbers and an easy-going nature.",
              accentHex: "8A8A3C"),

        Breed(id: "speckled-sussex", name: "Speckled Sussex", purpose: .dual,
              eggsPerYear: 250, eggColor: .cream, eggSize: .large, weightLb: 7.0,
              coldHardiness: 4, heatTolerance: 4, calmness: 4, friendliness: 5,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 4, foraging: 5,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Curious and people-loving", "Good forager", "Lays through winter"],
              cons: ["Can be too friendly underfoot"],
              appearance: "Mahogany feathers tipped with white speckles that grow each moult.",
              summary: "A chatty, affectionate forager that keeps laying when days get short.",
              accentHex: "C2683A"),

        Breed(id: "silver-wyandotte", name: "Silver-Laced Wyandotte", purpose: .dual,
              eggsPerYear: 200, eggColor: .brown, eggSize: .medium, weightLb: 6.5,
              coldHardiness: 5, heatTolerance: 3, calmness: 4, friendliness: 3,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 5, foraging: 3,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Very cold hardy rose comb", "Handles confinement", "Beautiful lacing"],
              cons: ["Can be aloof", "Moderate layer"],
              appearance: "Silver feathers each outlined in black — a living stained-glass pattern.",
              summary: "Built for cold coops: a tidy rose-combed hen that tolerates close quarters.",
              accentHex: "6E5A2C"),

        Breed(id: "black-copper-marans", name: "Black Copper Marans", purpose: .dual,
              eggsPerYear: 200, eggColor: .darkBrown, eggSize: .large, weightLb: 7.0,
              coldHardiness: 4, heatTolerance: 3, calmness: 4, friendliness: 3,
              flightiness: 2, noise: 2, broodiness: 2, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn],
              pros: ["Famous chocolate-brown eggs", "Calm and quiet", "Cold tolerant"],
              cons: ["Slower to start laying"],
              appearance: "Black feathers with coppery hackles and lightly feathered shanks.",
              summary: "Lays the darkest, glossiest brown eggs you can get — a calm, handsome bird.",
              accentHex: "8A4B25"),

        Breed(id: "ameraucana", name: "Ameraucana", purpose: .eggs,
              eggsPerYear: 250, eggColor: .blue, eggSize: .medium, weightLb: 5.5,
              coldHardiness: 5, heatTolerance: 4, calmness: 3, friendliness: 3,
              flightiness: 3, noise: 2, broodiness: 2, confinementTolerance: 3, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["True blue eggs", "Cold-hardy pea comb", "Quiet"],
              cons: ["Can be skittish", "Harder to source pure"],
              appearance: "Muffs and a beard frame bright eyes; slate-blue legs.",
              summary: "Genuine blue eggs from a hardy, frost-proof bird with a charming bearded face.",
              accentHex: "A8CBD6"),

        Breed(id: "easter-egger", name: "Easter Egger", purpose: .eggs,
              eggsPerYear: 280, eggColor: .green, eggSize: .medium, weightLb: 5.0,
              coldHardiness: 4, heatTolerance: 4, calmness: 4, friendliness: 4,
              flightiness: 3, noise: 2, broodiness: 2, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Colourful blue/green eggs", "Friendly and hardy", "Great starter bird"],
              cons: ["Egg colour varies per bird"],
              appearance: "Every bird is unique — endless feather colours and cheeky muffs.",
              summary: "The rainbow-basket favourite: hardy, friendly and full of surprises.",
              accentHex: "AEBE8A"),

        Breed(id: "brahma", name: "Light Brahma", purpose: .dual,
              eggsPerYear: 150, eggColor: .brown, eggSize: .medium, weightLb: 9.5,
              coldHardiness: 5, heatTolerance: 2, calmness: 5, friendliness: 4,
              flightiness: 1, noise: 1, broodiness: 3, confinementTolerance: 5, foraging: 3,
              layingSeasons: [.autumn, .winter, .spring],
              pros: ["Lays in deep winter", "Gentle giant", "Feathered feet, very cold hardy"],
              cons: ["Slow growing", "Mud cakes feathered feet"],
              appearance: "Towering white bird with black hackles and fluffy feathered legs.",
              summary: "A majestic, mellow giant that quietly lays right through the coldest months.",
              accentHex: "E0982A"),

        Breed(id: "cornish", name: "Dark Cornish", purpose: .meat,
              eggsPerYear: 160, eggColor: .brown, eggSize: .medium, weightLb: 8.0,
              coldHardiness: 3, heatTolerance: 4, calmness: 4, friendliness: 3,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 4, foraging: 3,
              layingSeasons: [.spring, .summer],
              pros: ["Broad, meaty body", "Calm temperament", "Good in heat"],
              cons: ["Low egg output", "Wide stance needs space"],
              appearance: "Compact, muscular bird with iridescent dark-laced feathers.",
              summary: "The classic meat breed: heavy, well-muscled and surprisingly docile.",
              accentHex: "8A4B25"),

        Breed(id: "jersey-giant", name: "Jersey Giant", purpose: .meat,
              eggsPerYear: 180, eggColor: .brown, eggSize: .extraLarge, weightLb: 10.0,
              coldHardiness: 5, heatTolerance: 2, calmness: 5, friendliness: 4,
              flightiness: 1, noise: 2, broodiness: 2, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.autumn, .winter, .spring],
              pros: ["Largest pure breed", "Very cold hardy", "Calm and gentle"],
              cons: ["Slow to mature", "Eats a lot"],
              appearance: "Massive glossy-black bird, calm and statuesque.",
              summary: "The biggest chicken there is — a gentle, cold-proof dual bird for big appetites.",
              accentHex: "6E5A2C"),

        Breed(id: "silkie", name: "Silkie", purpose: .ornamental,
              eggsPerYear: 110, eggColor: .cream, eggSize: .small, weightLb: 2.5,
              coldHardiness: 3, heatTolerance: 3, calmness: 5, friendliness: 5,
              flightiness: 1, noise: 1, broodiness: 5, confinementTolerance: 5, foraging: 2,
              layingSeasons: [.spring, .summer, .autumn],
              pros: ["Adorable, perfect for kids", "Best broody mother", "Tolerates confinement"],
              cons: ["Few eggs", "Fluff needs dry coop"],
              appearance: "Cloud-soft fur-like plumage, black skin and a pom-pom crest.",
              summary: "More pet than producer: irresistibly fluffy, gentle and famously broody.",
              accentHex: "F4BE5A"),

        Breed(id: "polish", name: "Polish", purpose: .ornamental,
              eggsPerYear: 180, eggColor: .white, eggSize: .small, weightLb: 4.0,
              coldHardiness: 3, heatTolerance: 3, calmness: 3, friendliness: 3,
              flightiness: 4, noise: 3, broodiness: 1, confinementTolerance: 3, foraging: 3,
              layingSeasons: [.spring, .summer, .autumn],
              pros: ["Show-stopping crest", "Decent white-egg layer", "Eye-catching"],
              cons: ["Crest blocks vision — startles easily", "Crest gets wet"],
              appearance: "Wild feathered top-hat crest over a slim, dapper body.",
              summary: "The flock's showpiece — flamboyant crest, lively nature and tidy white eggs.",
              accentHex: "8A8A3C"),

        Breed(id: "welsummer", name: "Welsummer", purpose: .dual,
              eggsPerYear: 200, eggColor: .darkBrown, eggSize: .large, weightLb: 6.0,
              coldHardiness: 4, heatTolerance: 4, calmness: 4, friendliness: 4,
              flightiness: 3, noise: 2, broodiness: 2, confinementTolerance: 3, foraging: 5,
              layingSeasons: [.spring, .summer, .autumn],
              pros: ["Speckled terracotta eggs", "Smart forager", "Friendly"],
              cons: ["Prefers room to roam"],
              appearance: "Rich partridge-patterned hen — the classic cornflakes rooster's mate.",
              summary: "Lays gorgeous speckled dark eggs and loves to free-range and forage.",
              accentHex: "C2683A"),

        Breed(id: "faverolles", name: "Salmon Faverolles", purpose: .dual,
              eggsPerYear: 180, eggColor: .cream, eggSize: .medium, weightLb: 6.5,
              coldHardiness: 5, heatTolerance: 3, calmness: 5, friendliness: 5,
              flightiness: 1, noise: 1, broodiness: 3, confinementTolerance: 5, foraging: 3,
              layingSeasons: [.autumn, .winter, .spring],
              pros: ["Sweet, gentle, great with kids", "Lays in winter", "Tolerates confinement"],
              cons: ["Bullied by pushy breeds", "Muddy feathered feet"],
              appearance: "Fluffy salmon-and-cream feathers, a beard, and five toes.",
              summary: "An exceptionally gentle, fluffy bird that keeps laying through the cold.",
              accentHex: "F4BE5A"),

        Breed(id: "andalusian", name: "Blue Andalusian", purpose: .eggs,
              eggsPerYear: 250, eggColor: .white, eggSize: .large, weightLb: 5.5,
              coldHardiness: 3, heatTolerance: 5, calmness: 2, friendliness: 2,
              flightiness: 4, noise: 3, broodiness: 1, confinementTolerance: 2, foraging: 5,
              layingSeasons: [.spring, .summer, .autumn],
              pros: ["Elegant slate-blue plumage", "Thrives in heat", "Active forager"],
              cons: ["Flighty and aloof", "Dislikes confinement"],
              appearance: "Slate-blue feathers laced in darker blue, sleek and alert.",
              summary: "A heat-loving Mediterranean layer of white eggs — striking but independent.",
              accentHex: "A8CBD6"),

        Breed(id: "new-hampshire", name: "New Hampshire Red", purpose: .dual,
              eggsPerYear: 240, eggColor: .brown, eggSize: .large, weightLb: 6.5,
              coldHardiness: 4, heatTolerance: 4, calmness: 4, friendliness: 4,
              flightiness: 2, noise: 2, broodiness: 3, confinementTolerance: 4, foraging: 4,
              layingSeasons: [.spring, .summer, .autumn, .winter],
              pros: ["Fast maturing", "Friendly and calm", "Good dual yields"],
              cons: ["Can be food-greedy"],
              appearance: "Chestnut-red plumage, a touch lighter and rounder than a Rhode Island.",
              summary: "A quick-growing, good-natured dual bird that lays well into winter.",
              accentHex: "C2683A")
    ]

    static func breed(_ id: String) -> Breed? { all.first { $0.id == id } }

    static func name(_ id: String) -> String { breed(id)?.name ?? "Unknown" }
}

protocol Reward {
    func offer() async -> Bool
    func wireClicker()
}

final class TreatReward: Reward {

    private let center = UNUserNotificationCenter.current()

    func offer() async -> Bool {
        let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
                cont.resume(returning: ok)
            }
        }
        if granted { wireClicker() }
        return granted
    }

    func wireClicker() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
