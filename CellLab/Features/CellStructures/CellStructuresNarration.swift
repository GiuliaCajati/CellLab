import Foundation

enum CSNarrationText {
    static let overview = """
    Fun fact! The average adult human body contains about 37.2 trillion cells. What keeps a tiny cell running? A whole team of little structures! The membrane controls what comes and goes, the nucleus holds most of the DNA instructions, and other parts build, deliver, recycle, and help the cell move. This is a simplified animal-cell model. Some features, such as cilia and a flagellum, are found only in certain cell types. Tap a part in the picture, choose its name, or explore the list of structures. I’ll explain its job and what the animation shows. Open Look closer whenever you’d like more detail. Let’s start with the nucleus!
    """

    static func sentence(_ text: String) -> String {
        guard let last = text.last else { return text }
        return ".!?".contains(last) ? text : text + "."
    }
}

extension CSPart {
    var narrationID: String { "structure.\(id)" }
    var detailNarrationID: String { "detail.\(id)" }
    var narrationText: String {
        [content.title, content.nickname, content.summary, content.action]
            .map(CSNarrationText.sentence).joined(separator: " ")
    }
    var detailNarrationText: String {
        CSNarrationText.sentence(content.title) + "\n\n" + content.details.map(CSNarrationText.sentence).joined(separator: " ")
    }
}
