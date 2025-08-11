import Foundation

struct CorePackData {
    static let manifest = """
    {
      "id": "core",
      "name": "Core Pack",
      "version": "1.0.0",
      "description": "Essential prompt categories for daily ideation including wellness and personal growth",
      "author": "Idea Loom Team",
      "categories": [
        {
          "id": "personalDevelopment",
          "name": "Personal Development",
          "file": "personalDevelopment.tsv",
          "icon": "person.crop.circle.badge.checkmark",
          "color": "blue"
        },
        {
          "id": "professional",
          "name": "Professional",
          "file": "professional.tsv",
          "icon": "briefcase.fill",
          "color": "purple"
        },
        {
          "id": "creative",
          "name": "Creative",
          "file": "creative.tsv",
          "icon": "paintbrush.fill",
          "color": "orange"
        },
        {
          "id": "lifestyle",
          "name": "Lifestyle",
          "file": "lifestyle.tsv",
          "icon": "heart.fill",
          "color": "pink"
        },
        {
          "id": "relationships",
          "name": "Relationships",
          "file": "relationships.tsv",
          "icon": "person.2.fill",
          "color": "red"
        },
        {
          "id": "entertainment",
          "name": "Entertainment",
          "file": "entertainment.tsv",
          "icon": "tv.fill",
          "color": "yellow"
        },
        {
          "id": "travel",
          "name": "Travel & Adventure",
          "file": "travel.tsv",
          "icon": "airplane",
          "color": "green"
        },
        {
          "id": "learning",
          "name": "Learning & Skills",
          "file": "learning.tsv",
          "icon": "book.fill",
          "color": "indigo"
        },
        {
          "id": "financial",
          "name": "Financial",
          "file": "financial.tsv",
          "icon": "dollarsign.circle.fill",
          "color": "mint"
        },
        {
          "id": "socialImpact",
          "name": "Social Impact",
          "file": "socialImpact.tsv",
          "icon": "globe.americas.fill",
          "color": "teal"
        },
        {
          "id": "health",
          "name": "Health & Fitness",
          "file": "health.tsv",
          "icon": "heart.circle.fill",
          "color": "red"
        },
        {
          "id": "mindfulness",
          "name": "Mindfulness",
          "file": "mindfulness.tsv",
          "icon": "leaf.fill",
          "color": "green"
        },
        {
          "id": "selfcare",
          "name": "Self Care",
          "file": "selfcare.tsv",
          "icon": "sparkles",
          "color": "purple"
        },
        {
          "id": "gratitude",
          "name": "Gratitude",
          "file": "gratitude.tsv",
          "icon": "hands.sparkles",
          "color": "orange"
        }
      ]
    }
    """
    
    static func getTSVContent(for fileName: String) -> String? {
        switch fileName {
        case "personalDevelopment.tsv":
            return personalDevelopmentTSV
        case "professional.tsv":
            return professionalTSV
        case "creative.tsv":
            return creativeTSV
        case "lifestyle.tsv":
            return lifestyleTSV
        case "relationships.tsv":
            return relationshipsTSV
        case "entertainment.tsv":
            return entertainmentTSV
        case "travel.tsv":
            return travelTSV
        case "learning.tsv":
            return learningTSV
        case "financial.tsv":
            return financialTSV
        case "socialImpact.tsv":
            return socialImpactTSV
        case "health.tsv":
            return healthTSV
        case "mindfulness.tsv":
            return mindfulnessTSV
        case "selfcare.tsv":
            return selfcareTSV
        case "gratitude.tsv":
            return gratitudeTSV
        default:
            return nil
        }
    }
    
    private static let personalDevelopmentTSV = """
    text
    things to accomplish in the next decade
    habits to develop this year
    fears to overcome
    skills I'd like to master
    ways to improve my morning routine
    things I'm grateful for today
    things I would do if I knew I could not fail
    """
    
    private static let professionalTSV = """
    text
    business ideas to explore
    ways to improve my workspace
    networking opportunities to pursue
    career goals for the next 5 years
    ways to add value to my team
    side projects to start this month
    """
    
    private static let creativeTSV = """
    text
    short story concepts
    inventions that would make life easier
    art projects to try
    podcast episode ideas
    app ideas that solve real problems
    YouTube video concepts
    """
    
    private static let lifestyleTSV = """
    text
    bucket list adventures
    recipes to try this month
    ways to simplify my life
    healthy habits to adopt
    ways to reduce stress
    home improvement projects
    """
    
    private static let relationshipsTSV = """
    text
    ways to show appreciation to loved ones
    conversation starters for meaningful discussions
    qualities I value in friendships
    ways to strengthen my relationships
    people I should reconnect with
    """
    
    private static let entertainmentTSV = """
    text
    movie night themes
    book genres to explore
    games to play with friends
    types of live events to experience
    hobbies to explore
    """
    
    private static let travelTSV = """
    text
    types of local adventures to try
    dream vacation themes
    road trip themes or activities
    unique travel experiences I'd enjoy
    weekend getaway themes
    """
    
    private static let learningTSV = """
    text
    subjects I want to learn more about
    languages I'd like to learn
    documentary topics that interest me
    skills that would advance my career
    topics I'm curious about
    """
    
    private static let financialTSV = """
    text
    ways to save money
    investment opportunities to explore
    financial goals for this year
    ways to increase my income
    """
    
    private static let socialImpactTSV = """
    text
    causes to support
    ways to help my community
    environmental changes to make
    volunteer opportunities to pursue
    random acts of kindness to perform
    """
    
    private static let healthTSV = """
    text
    healthy snacks to prepare
    movement activities that sound fun
    sleep hygiene improvements to make
    ways to stay hydrated
    stretches to do during work breaks
    outdoor activities to try
    healthy meal prep ideas
    ways to reduce screen time
    morning routines for energy
    stress-relief activities
    """
    
    private static let mindfulnessTSV = """
    text
    moments today when I felt present
    thoughts I can let go of
    sensations I'm noticing right now
    breathing exercises to try
    meditation techniques to explore
    ways to ground myself when anxious
    mindful activities for this week
    triggers I want to be aware of
    intentions for tomorrow
    types of peaceful environments I enjoy
    """
    
    private static let selfcareTSV = """
    text
    ways to pamper myself this weekend
    boundaries I need to set
    self-care rituals to establish
    activities that recharge my energy
    ways to say no without guilt
    comfort activities for bad days
    positive affirmations I need to hear
    ways to celebrate small wins
    self-compassion practices to try
    rest activities that aren't sleep
    """
    
    private static let gratitudeTSV = """
    text
    small joys I experienced today
    people who made my life better
    abilities I'm grateful for
    challenges that helped me grow
    simple pleasures I often overlook
    things about my body I appreciate
    opportunities I'm thankful for
    memories that make me smile
    aspects of my home I love
    lessons I'm grateful to have learned
    """
}