CREATE OR REPLACE PACKAGE fc_deck_api AS
    -- Pitch deck for a tender: AI-drafted slides (FC_PITCH_SLIDES) and export formats (PPTX, HTML, PDF).

    -- Drafts 8 slides from the confirmed brief, the selected concept, fit checks and
    -- approved research. Falls back to the template deck when the AI is unavailable.
    PROCEDURE draft_slides(
        p_tender_id IN NUMBER,
        p_user_name IN VARCHAR2,
        x_message   OUT VARCHAR2
    );

    -- Interactively edits and remakes the 8 slides and PowerPoint based on a natural language chat prompt.
    PROCEDURE remake_slides_with_chat(
        p_tender_id   IN NUMBER,
        p_chat_prompt IN VARCHAR2,
        p_user_name   IN VARCHAR2,
        x_message     OUT VARCHAR2
    );

    -- Builds a .pptx (Office Open XML) file from the tender's slides.
    FUNCTION build_pptx(p_tender_id IN NUMBER) RETURN BLOB;

    -- Builds a standalone HTML5 presentation deck (.html) from the tender's slides.
    FUNCTION build_html(p_tender_id IN NUMBER) RETURN BLOB;

    -- Builds a presentation document (.pdf) from the tender's slides.
    FUNCTION build_pdf(p_tender_id IN NUMBER) RETURN BLOB;

    -- HTML preview of all slides for the Design page, with 3 export options: PPTX, HTML, PDF.
    FUNCTION render_preview(p_tender_id IN NUMBER) RETURN CLOB;
END fc_deck_api;
/
